Ah, that explains it! You are using **pyenv** (`/home/dmn/.pyenv/shims/python`), which manages your Python versions and
virtual environments globally.

Since you use pyenv, we should ensure Aider is installed cleanly within pyenv so it's always available without messing
with Debian's system packages.

Here is how to proceed with pyenv:

---

## 1. Install Aider via Pyenv

Since your active Python environment is managed by pyenv, simply install Aider using pip. Pyenv will automatically shim
it so you can run it from anywhere:

```bash
pip install --upgrade pip
pip install aider-chat

```

---

## 2. Configure Your OpenRouter API Key

Since you use `bash` (implied by standard pyenv setups), let's save your OpenRouter API key permanently so you don't
have to retype it:

1. Open your shell configuration file:

```bash
nano ~/.bashrc

```

2. Scroll to the bottom and add your key:

```bash
export OPENROUTER_API_KEY="sk-or-v1-your-actual-api-key"

```
OR 

Load AI API keys securely from local backup (ignored by git)

   ```bash 
    if [ -f "$HOME/dotfiles/.dotfiles_backup_ai_keys/api_keys_format.md" ]; then
        source "$HOME/dotfiles/.dotfiles_backup_ai_keys/api_keys_format.md"
    fi

    ```

# Convenience alias for launching Aider with DeepSeek + Qwen
alias aider-architect='aider --architect --model deepseek/deepseek-chat --editor-model dashscope/qwen3-vl-32b-instruct'

3. Add a handy alias to launch Aider with your DeepSeek + Qwen architect/editor setup instantly:

```bash
alias aider-architect='aider --architect --model deepseek/deepseek-chat --editor-model dashscope/qwen3-vl-32b-instruct'
```

or **openrouter**
```bash
alias aider-architect='aider --architect-model openrouter/deepseek/deepseek-chat --editor-model openrouter/qwen/qwen-2.5-coder-72b-instruct'

```

4. Save and exit (`Ctrl+O`, `Enter`, then `Ctrl+X`), then reload your shell:

```bash
source ~/.bashrc

```

---

## 3. Test It Out

Go to any project folder that is a Git repository, and launch your configured AI harness:

```bash
cd /path/to/your/project
aider-architect

```

Once Aider opens, you can add a file to its context using `/add filename.ext` and give it your first prompt! Let me know
if everything is running smoothly or if pyenv throws any path/shim warnings.