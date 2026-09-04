export const PROVIDERS = {
  openrouter: {
    title: 'OpenRouter',
    endpoint: 'https://openrouter.ai/api/v1/chat/completions',
    modelsEndpoint: 'https://openrouter.ai/api/v1/models',
    model: 'openai/gpt-4o-mini',
    placeholder: 'sk-or-…',
    copy: 'OpenAI-compatible Chat Completions with OpenRouter model routing.',
  },
  openai: {
    title: 'OpenAI',
    endpoint: 'https://api.openai.com/v1/chat/completions',
    modelsEndpoint: 'https://api.openai.com/v1/models',
    model: 'gpt-4o-mini',
    deviceEndpoint: 'https://chatgpt.com/backend-api/codex/responses',
    deviceModelsEndpoint: 'https://chatgpt.com/backend-api/codex/models?client_version=0.153.0',
    deviceModel: 'gpt-5.4-mini',
    placeholder: 'sk-…',
    copy: 'OpenAI Chat Completions with bearer-key authentication.',
  },
  anthropic: {
    title: 'Anthropic',
    endpoint: 'https://api.anthropic.com/v1/chat/completions',
    modelsEndpoint: 'https://api.anthropic.com/v1/models',
    model: 'claude-sonnet-4-6',
    placeholder: 'sk-ant-…',
    copy: 'Anthropic’s OpenAI-compatible endpoint, including function calls.',
  },
  custom: {
    title: 'Custom', endpoint: '', modelsEndpoint: '', model: '',
    placeholder: 'optional bearer token', copy: 'Any OpenAI-compatible Chat Completions endpoint.',
  },
}

export function providerOf(url = '') {
  return Object.entries(PROVIDERS).find(([id, provider]) => id !== 'custom' && (provider.endpoint === url || provider.deviceEndpoint === url))?.[0] || 'custom'
}
