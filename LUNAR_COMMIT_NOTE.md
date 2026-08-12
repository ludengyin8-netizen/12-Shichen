# Lunar Phase & SwiftAA

This commit adds SwiftAA as a package dependency (Package.swift) and creates a LunarAstronomyEngine skeleton that will be implemented using SwiftAA. At present the lunar engine provides a conservative lunar phase fraction estimate (synodic month fraction) and marks rise/set/transit as UNAVAILABLE until a validated SwiftAA-based implementation is added.

Files added:
- Package.swift (adds SwiftAA package via branch main)
- Sources/SHICHENApp/Engines/LunarAstronomyEngine.swift (skeleton + simple phase fraction)
- Sources/SHICHENApp/Engines/CombinedAstronomyEngine.swift (combines solar + lunar engines)
- Sources/SHICHENApp/AppState+CombinedService.swift (wires AppState to use CombinedAstronomyEngine)

Branch: v3-lunar
