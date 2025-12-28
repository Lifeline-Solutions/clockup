require 'rails_helper'

describe Api::V1::UssdController, type: :controller do
  let(:user) { create(:user, phone_number: '+254712345678') }
  let(:organisation) { user.organisation }

  describe 'POST #handle' do
    context 'with valid phone number' do
      it 'returns initial menu when text is empty' do
        post :handle, params: {
          phoneNumber: user.phone_number,
          text: '',
          sessionId: 'test123'
        }

        expect(response.body).to include('CON Welcome to ClockUp')
      end

      it 'clocks in user when text is 1' do
        post :handle, params: {
          phoneNumber: user.phone_number,
          text: '1',
          sessionId: 'test123'
        }

        expect(response.body).to include('END ✓ Clock In successful')
        expect(user.clock_events.count).to eq(1)
      end

      it 'clocks out user when text is 2' do
        create(:clock_event, user: user, organisation: organisation, event_type: :clock_in, occurred_at: 1.hour.ago)

        post :handle, params: {
          phoneNumber: user.phone_number,
          text: '2',
          sessionId: 'test123'
        }

        expect(response.body).to include('END ✓ Clock Out successful')
      end

      it 'shows status when text is 3' do
        post :handle, params: {
          phoneNumber: user.phone_number,
          text: '3',
          sessionId: 'test123'
        }

        expect(response.body).to include('END Status: Clocked Out')
      end
    end

    context 'with invalid phone number' do
      it 'returns user not found message' do
        post :handle, params: {
          phoneNumber: '+999999999999',
          text: '',
          sessionId: 'test123'
        }

        expect(response.body).to include('END User not found')
      end
    end

    context 'with missing phone number' do
      it 'returns invalid request' do
        post :handle, params: {
          text: '',
          sessionId: 'test123'
        }

        expect(response.body).to include('END Invalid request')
      end
    end
  end
end
