#if compiler(>=6.0)
@preconcurrency import ProjectDescription
#else
import ProjectDescription
#endif

let config = Tuist()
