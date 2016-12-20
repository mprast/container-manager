# Container Manager (cm)
For now, contains miscellaneous scripts to manage containers and container lifecycles.
Eventually will evolve into a fuller-fleged application.

# Notes for matt
1. implement an 'investigate' option that lets you mount a rootfs in a 'containers' dir (which is mounted in the dev container). This lets the developer debug the filesystem of a running container as needed
2. implement an 'edit' mode - this should copy the 'src' dir of a container to a 'src' dir in the local filesystem (which is mounted in the dev container). Then it should restart the container mounting the copy in place of the original. OPEN QUESTION: how do we keep the container from being gc'd after it's been shut down but before we've copied the source? Any way to exclude it from being considered by gc?
