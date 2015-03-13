export ANDROID_HOME='/Users/John/Android/sdk'
export PATH=${PATH}:$ANDROID_HOME/tools
export PATH=${PATH}:$ANDROID_HOME/platform-tools

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi
