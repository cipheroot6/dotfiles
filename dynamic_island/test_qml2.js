const { execSync } = require('child_process');
const args = ["- [ ] test 1", "- [ ] test 2"];
execSync('sh -c \'printf "%s\\n" "$@" > test_out2.txt\' /tmp/todo ' + args.map(a => `"${a}"`).join(' '));
