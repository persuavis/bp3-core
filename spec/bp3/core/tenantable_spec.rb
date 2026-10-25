# frozen_string_literal: true

# How far Tenantable's default scopes reach: as far as the primary login, the request state's
# current_login, the least privileged one signed in.
RSpec.describe Bp3::Core::Tenantable do
  # The readers of Bp3::RequestState::Base the decision uses, with current_login as it defines it
  let(:state_class) do
    Struct.new(:current_user, :current_admin, :current_root, keyword_init: true) do
      def current_login
        current_user || current_admin || current_root
      end
    end
  end

  let(:user) { Object.new }
  let(:admin) { Object.new }
  let(:root) { Object.new }

  def reach(**logins)
    state = state_class.new(**logins)
    [described_class.reaches_every_site?(state), described_class.reaches_every_tenant?(state)]
  end

  it 'reaches one site and tenant with nobody signed in' do
    expect(reach).to eq([false, false])
  end

  it 'reaches every site for a root' do
    expect(reach(current_root: root)).to eq([true, true])
  end

  it 'reaches every tenant of the site for an admin' do
    expect(reach(current_admin: admin)).to eq([false, true])
  end

  it 'reaches one site and tenant for a user' do
    expect(reach(current_user: user)).to eq([false, false])
  end

  it 'reaches as far as the user for a root signed in beside a user' do
    expect(reach(current_root: root, current_user: user)).to eq([false, false])
  end

  it 'reaches as far as the user for an admin signed in beside a user' do
    expect(reach(current_admin: admin, current_user: user)).to eq([false, false])
  end

  it 'reaches as far as the admin for a root signed in beside an admin' do
    expect(reach(current_root: root, current_admin: admin)).to eq([false, true])
  end
end
