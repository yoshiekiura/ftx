require 'spec_helper'

describe 'member tags' do
  let!(:identity) { create :identity }
  let!(:member) { create :member, email: identity.email, tag_list: 'hero' }

  # Not necessary
  # it 'user can view self tags in settings index' do
  #   pending
  #   signin identity
  #   visit settings_path
  #   expect(page).to have_content 'Hero Member'
  # end
end
