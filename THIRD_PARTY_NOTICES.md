<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
PURPOSE: Separate the project license from platform dependencies and cited physics research.
SRP/DRY check: Pass — checked existing README, specification and history; links retain one source for detailed design.
-->
# Dependencies and research references

The root MIT license covers the project contributions that their rights holders may license. It does not license Apple frameworks, Unreal Engine, outside papers or future imported assets.

## Current runtime and assets

- The package manifest contains only local targets, with no remote package dependencies.
- The app imports Apple frameworks supplied with Xcode and the operating system. Their terms remain Apple's; this repository does not redistribute their source or binaries.
- Table and ball geometry and textures are constructed in Swift, and impact sounds are synthesized in code. No purchased art, font, sound or model files were found among the published historical files. System drawing/text services are used for ball labels.
- No Unreal Engine source or purchased dog-game assets are in this tree. The later Unreal direction does not grant rights to redistribute those separately licensed materials.

## Physics design references

The [specification references](docs/2026-11-02-breakdown-spec.md#13-references) credit Evan Kiefl's pool simulator and theory work, Dave Alciatore's technical proofs, Leckie and Greenspan, Mathavan/Jackson/Parkin, Han, Marlow and regulation billiards dimensions. These are design/research references, not bundled libraries. The numerical friction fit in the current parameters follows the design's Alciatore-style fit; the spec itself flags original-source verification and calibration as unfinished. Preserve that attribution and verify those sources before presenting the solver as validated.

No third-party copyright header or copied library distribution was identified in this review. This is a source/history inspection, not proof of authorship or a legal ownership certification. If an imported implementation or asset is later identified, preserve its notices and resolve its terms before publication.
