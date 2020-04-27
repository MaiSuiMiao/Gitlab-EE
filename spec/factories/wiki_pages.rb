# frozen_string_literal: true

require 'ostruct'

FactoryBot.define do
  factory :wiki_page do
    transient do
      title { generate(:wiki_page_title) }
      content { 'Content for wiki page' }
      format { :markdown }
      message { nil }
      project { association(:project, :wiki_repo) }
      container { project }
      wiki { association(:wiki, container: container) }
      page { OpenStruct.new(url_path: title) }
    end

    initialize_with do
      new(wiki, page).tap do |page|
        page.attributes = {
          title: title,
          content: content,
          format: format
        }
      end
    end

    # Clear our default @page, except when using build_stubbed
    after(:build) do |page|
      page.instance_variable_set('@page', nil)
    end

    to_create do |page, evaluator|
      page.create(message: evaluator.message)
    end
  end

  factory :wiki_page_meta, class: 'WikiPage::Meta' do
    title { generate(:wiki_page_title) }
    project { create(:project) }

    trait :for_wiki_page do
      transient do
        wiki_page { create(:wiki_page, container: project) }
      end

      project { @overrides[:wiki_page]&.container || create(:project) }
      title { wiki_page.title }

      initialize_with do
        raise 'Metadata only available for valid pages' unless wiki_page.valid?

        WikiPage::Meta.find_or_create(wiki_page.slug, wiki_page)
      end
    end
  end

  factory :wiki_page_slug, class: 'WikiPage::Slug' do
    wiki_page_meta { create(:wiki_page_meta) }
    slug { generate(:sluggified_title) }
    canonical { false }

    trait :canonical do
      canonical { true }
    end
  end

  sequence(:wiki_page_title) { |n| "Page #{n}" }
  sequence(:sluggified_title) { |n| "slug-#{n}" }
end
