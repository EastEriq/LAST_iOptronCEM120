# LAST_iOptronCEM120
iOptron CEM120 mounts matlab hardware class for LAST.

Ancestor project: [IOptronMountMatlab](https://github.com/EastEriq/IOptronMountMatlab).

It is left to the responsibility of the LAST integrator to copy or link the files of this project into an `+obs\+instr` tree. I couln't think of any viable directory structure satisfying both `git` project naming constraints (even considering `subtree`s and `submodule`s) and Matlab/MAAT/LAST organization requirements.

## TODO:

+ getters and setters for time when not supplied by the GPS

+ implement parking to Alt<0 as a GoTo. Reason for doing: its a must for functionality.
  Reason for not doing: it is convenient to query the mount about its set park position,
  but the firmware allows only setting positive park Alt. The park position stored into
  the mount survives across power cycles and matlab sessions, an alternative park position
  property stored in the class, not.