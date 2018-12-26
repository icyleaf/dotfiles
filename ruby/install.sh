rvm_db_path="$HOME/.rvm/user/db"
rvm_ruby_url="ruby_url=https://cache.ruby-china.org/pub/ruby"

if ! grep -q "$rvm_ruby_url" $rvm_db_path; then
  echo " > Replace RVM source to taobao"
  echo "ruby_url=https://cache.ruby-china.org/pub/ruby" > ~/.rvm/user/db
fi
