# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::Models do
  let(:client) { test_client }
  let(:models) { client.models }

  def model_payload(model_id, can_do_tts: true)
    {
      model_id: model_id,
      name: model_id.tr('_', ' '),
      can_do_text_to_speech: can_do_tts,
      languages: [{ language_id: 'en' }],
      model_rates: { character_cost_multiplier: 1.0 },
      maximum_text_length_per_request: 10_000,
      requires_alpha_access: false
    }
  end

  context 'with eleven_v4 on the account' do
    before do
      stub_elevenlabs_request(:get, '/models',
                              response_body: [model_payload('eleven_multilingual_v2'), model_payload('eleven_v4')])
    end

    it 'lists models without recursing (regression: #get shadowed Base#get)' do
      list = models.list

      expect(list.map(&:model_id)).to eq(%w[eleven_multilingual_v2 eleven_v4])
      expect(list).to all(be_a(ElevenRb::Objects::Model))
    end

    it 'finds a model by id' do
      expect(models.find('eleven_v4').model_id).to eq('eleven_v4')
      expect(models.find('missing')).to be_nil
    end

    it 'keeps #get as an alias of #find' do
      expect(models.get('eleven_multilingual_v2').model_id).to eq('eleven_multilingual_v2')
    end

    it 'returns eleven_v4 as the latest model' do
      expect(models.latest.model_id).to eq('eleven_v4')
    end

    it 'returns TTS-capable models and ids' do
      expect(models.tts_capable.size).to eq(2)
      expect(models.ids).to eq(%w[eleven_multilingual_v2 eleven_v4])
      expect(models.default.model_id).to eq('eleven_multilingual_v2')
    end

    it 'exposes the new model attributes' do
      model = models.find('eleven_v4')

      expect(model.model_rates).to eq('character_cost_multiplier' => 1.0)
      expect(model.maximum_text_length_per_request).to eq(10_000)
      expect(model.requires_alpha_access).to be(false)
      expect(model.supported_voice_settings).to eq(%i[stability similarity_boost])
    end

    it 'lets the TTS adapter list models' do
      expect(client.adapter.list_models.map { |m| m[:model_id] }).to eq(%w[eleven_multilingual_v2 eleven_v4])
    end
  end

  context 'without eleven_v4' do
    it 'falls back to the default model with a single /models request' do
      stub = stub_elevenlabs_request(:get, '/models', response_body: [model_payload('eleven_multilingual_v2')])

      expect(models.latest.model_id).to eq('eleven_multilingual_v2')
      expect(stub).to have_been_requested.once
    end

    it 'falls back to the first TTS-capable model with a single /models request' do
      stub = stub_elevenlabs_request(:get, '/models',
                                     response_body: [model_payload('eleven_sts', can_do_tts: false),
                                                     model_payload('eleven_flash_v2_5')])

      expect(models.latest.model_id).to eq('eleven_flash_v2_5')
      expect(models.default.model_id).to eq('eleven_flash_v2_5')
      expect(stub).to have_been_requested.twice
    end

    it 'falls back to eleven_v3' do
      stub_elevenlabs_request(:get, '/models',
                              response_body: [model_payload('eleven_multilingual_v2'), model_payload('eleven_v3')])

      expect(models.latest.model_id).to eq('eleven_v3')
    end

    it 'falls back to the default model' do
      stub_elevenlabs_request(:get, '/models',
                              response_body: [model_payload('eleven_flash_v2_5'), model_payload('eleven_multilingual_v2')])

      expect(models.latest.model_id).to eq('eleven_multilingual_v2')
    end
  end
end
