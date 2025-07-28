class UserKanjiPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    scope.where(user_id: user.id)
  end

  def show?
    record.user == user
  end

  def update?
    record.user == user
  end

  def destroy?
    record.user == user
  end

  def create?
    user.present?
  end
end
