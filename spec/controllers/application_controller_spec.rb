require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe 'GET #index' do
    it 'should redirect to welcome for new users' do
      get :index
      should redirect_to welcome_path
    end

    it 'should assign items' do
      request.cookies[:welcomed] = true
      get :index
      should render_template :index
      expect(assigns(:items)).to_not be_nil
    end

    it 'should create a new session' do
      request.cookies[:welcomed] = true
      expect { get :index }.to change { Session.count }.by(1)
    end

    it 'should use an old session' do
      request.cookies[:session] = create(:session).identifier
      expect { get :index }.to_not change { Session.count }
    end

    it 'should retrieve a session' do
      create(:session, identifier: 'some_session')
      expect { get :index, session: 'some_session' }
        .to_not change { Session.count }
    end

    it 'should return a json item list' do
      item_json = [create(:item)].to_json
      get :index, format: 'json'
      expect(response.body).to eq(item_json)
    end

    it 'should sync the session when given a valid parameter' do
      get :index, session: 'adjnoun'
      expect(assigns(:session).identifier).to eq('adjnoun')
    end

    it 'should auto-welcome syncing users' do
      get :index, session: 'adjnoun'
      expect(response.cookies['welcomed']).to eq('true')
    end
  end

  describe 'GET #all' do
    it 'should redirect to welcome for new users' do
      get :all
      should redirect_to welcome_path
    end

    it 'should return items from all sources' do
      source_items = [].tap do |items|
        3.times { items << create(:item, source: SOURCES.sample) }
      end
      request.cookies[:welcomed] = true
      get :all
      expect(assigns(:items)).to eq(source_items)
    end

    it 'should return a json item list' do
      item_json = [create(:item)].to_json
      get :all, format: 'json'
      expect(response.body).to eq(item_json)
    end
  end

  describe 'GET #custom' do
    it 'should redirect to welcome for new users' do
      get :custom
      should redirect_to welcome_path
    end

    it 'should return items matching session sources' do
      10.times { create(:item, source: SOURCES.sample) }
      session = create(:session, sources: SOURCES.shuffle.take(4))
      request.cookies[:welcomed] = true
      request.cookies[:session] = session.identifier
      get :custom
      expect(assigns(:items).pluck(:source) - session.sources).to be_empty
    end
  end

  describe 'GET #welcome' do
    it 'should set welcomed and session cookies' do
      get :welcome
      expect(response.cookies['welcomed']).to eq('true')
      expect(response.cookies['session']).to_not be_nil
    end
  end

  describe 'GET #feedback' do
    it 'should feedback render_template' do
      get :feedback
      should render_template :feedback
    end
  end

  describe 'set_link_behavior' do
    it 'should set link_target cookie' do
      get :set_link_behavior
      expect(response.cookies['link_target']).to_not be_nil
    end

    it 'should set the link_target cookie to the choice' do
      choice = %w(0 1).sample
      get :set_link_behavior, choice: choice
      expect(response.cookies['link_target']).to eq(choice)
    end

    it 'should redirect_to root if referer is nil' do
      request.env['HTTP_REFERER'] = custom_path
      get :set_link_behavior
      expect(response).to redirect_to(custom_path)
    end

    it 'should redirect_to root if referer is nil' do
      request.env['HTTP_REFERER'] = nil
      get :set_link_behavior
      expect(response).to redirect_to(root_path)
    end
  end
end
