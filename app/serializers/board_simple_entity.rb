# frozen_string_literal: true

class BoardSimpleEntity < Grape::Entity
  expose :id
end

BoardSimpleEntity.prepend(EE::BoardSimpleEntity)
