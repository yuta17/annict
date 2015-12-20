class PersonDecorator < ApplicationDecorator
  include PersonDecoratorCommon

  def db_detail_link(options = {})
    path = if h.current_user.role.admin? || h.current_user.role.editor?
      h.edit_db_person_path(self)
    else
      h.new_db_draft_person_path(person_id: id)
    end

    h.link_to name, path, options
  end
end
