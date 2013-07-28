Put your custom expression2 extensions in here.
They will be automatically loaded at runtime.

For each file, there can be a client part, which must be prefixed with "cl_".
This part will then be transferred to and loaded on the client.

Example:
If there is a file named "foo.lua" it will be loaded on the server.
If, in addition to that, there is a file named "cl_foo.lua", it will be transferred to and loaded on the client.
