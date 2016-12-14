1. Figure out how to get rkt to work with sudo-ers to give the dev container minimal necessary privileges. When we run /bin/bash in the container, is the process really root?
2. Set up ssh-agent forwarding so people's identities can follow them around. [Better served by something like okta? How do we handle two-factor?]
