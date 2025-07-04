# 🔑 API Keys para TaskMaster AI

## ⚡ CONFIGURACIÓN RÁPIDA

1. **Abre Cursor Settings**: `Ctrl+Shift+J`
2. **Ve a la pestaña MCP** en el lado izquierdo
3. **Activa task-master-ai** con el toggle
4. **Edita el archivo** `.cursor/mcp.json` y reemplaza las claves

## 🎯 API KEYS NECESARIAS (MÍNIMO 1)

### 🔥 RECOMENDADAS (Para el video workflow):

```json
"ANTHROPIC_API_KEY": "sk-ant-..."  // Claude 3.5 Sonnet (PRINCIPAL)
"PERPLEXITY_API_KEY": "pplx-..."   // Sonar Pro (RESEARCH)
```

### 🚀 ALTERNATIVAS:

```json
"OPENAI_API_KEY": "sk-..."         // GPT-4o/o1 (Alternativa principal)
"GOOGLE_API_KEY": "AIza..."        // Gemini 2.0 Flash (Alternativa)
"XAI_API_KEY": "xai-..."           // Grok (Alternativa)
```

### 💡 OPCIONALES:

```json
"MISTRAL_API_KEY": "..."
"OPENROUTER_API_KEY": "sk-or-..."
"AZURE_OPENAI_API_KEY": "..."
"OLLAMA_API_KEY": "..."
```

## 🎮 CONFIGURACIÓN COMO EN EL VIDEO:

1. **Modelo Principal**: Claude 3.5 Sonnet (para gestión de tareas)
2. **Modelo Research**: Perplexity Sonar Pro (para research online)
3. **Modelo Fallback**: GPT-4o o Gemini 2.0 Flash

## 🚀 PRÓXIMOS PASOS:

1. ✅ Conseguir API keys (mínimo Anthropic + Perplexity)
2. ✅ Actualizar `.cursor/mcp.json` con tus keys reales
3. ✅ Reiniciar Cursor
4. ✅ En el chat de Cursor decir: "Initialize taskmaster-ai in my project"
5. ✅ Parsear nuestro PRD: "Can you parse my PRD at .taskmaster/docs/prd.txt?"

## 🔗 DONDE CONSEGUIR LAS KEYS:

- **Anthropic**: https://console.anthropic.com/
- **Perplexity**: https://www.perplexity.ai/settings/api
- **OpenAI**: https://platform.openai.com/api-keys
- **Google**: https://aistudio.google.com/app/apikey

¡Una vez que tengas las keys, estarás listo para usar TaskMaster como en el video! 🔥 