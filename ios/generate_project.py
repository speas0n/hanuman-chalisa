#!/usr/bin/env python3
"""Generate the checked-in Xcode project using only Python's standard library."""
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
objects = {}

def obj(isa, **kwargs):
    key = f"{len(objects) + 1:024X}"
    objects[key] = dict(isa=isa, **kwargs)
    return key

file_refs = {}

def file(path, kind):
    # One reference per path, so a file shared by two targets appears once in the navigator.
    if path not in file_refs:
        file_refs[path] = obj("PBXFileReference", path=path, lastKnownFileType=kind, sourceTree="<group>")
    return file_refs[path]

def config(settings):
    entries = []
    for name in ("Debug", "Release"):
        values = dict(settings)
        if name == "Debug":
            values.update(SWIFT_OPTIMIZATION_LEVEL="-Onone", SWIFT_ACTIVE_COMPILATION_CONDITIONS="DEBUG", ENABLE_TESTABILITY="YES", DEBUG_INFORMATION_FORMAT="dwarf")
        else:
            values.update(SWIFT_COMPILATION_MODE="wholemodule", DEBUG_INFORMATION_FORMAT="dwarf-with-dsym")
        entries.append(obj("XCBuildConfiguration", name=name, buildSettings=values))
    return obj("XCConfigurationList", buildConfigurations=entries, defaultConfigurationIsVisible=0, defaultConfigurationName="Release")

base = dict(SDKROOT="iphoneos", IPHONEOS_DEPLOYMENT_TARGET="17.0", SWIFT_VERSION="5.0", CLANG_ENABLE_MODULES="YES", TARGETED_DEVICE_FAMILY="1", CODE_SIGN_STYLE="Automatic", GENERATE_INFOPLIST_FILE="YES", PRODUCT_NAME="$(TARGET_NAME)", CURRENT_PROJECT_VERSION="1", MARKETING_VERSION="1.0", SWIFT_EMIT_LOC_STRINGS="YES")
groups, products, targets = [], [], []

def target(name, folder, product_type, extra, resources=(), shared=(), plist=None):
    own = [file(f"{folder}/{p.name}", "sourcecode.swift") for p in sorted((ROOT / folder).glob("*.swift"))]
    sources = own + [file(path, "sourcecode.swift") for path in shared]
    refs = [file(path, kind) for path, kind in resources]
    if plist:
        extra = dict(extra, INFOPLIST_FILE=plist)
    listed = own + [ref for ref in refs if ref not in {r for g in groups for r in objects[g]["children"]}]
    group = obj("PBXGroup", name=name, children=listed + ([file(plist, "text.plist.xml")] if plist else []), sourceTree="<group>")
    groups.append(group)
    phases = []
    for isa, files in [("PBXSourcesBuildPhase", sources), ("PBXFrameworksBuildPhase", []), ("PBXResourcesBuildPhase", refs)]:
        phases.append(obj(isa, buildActionMask=2147483647, files=[obj("PBXBuildFile", fileRef=f) for f in files], runOnlyForDeploymentPostprocessing=0))
    extension, wrapper = {"application": ("app", "wrapper.application"), "app-extension": ("appex", "wrapper.app-extension")}.get(product_type, ("xctest", "wrapper.cfbundle"))
    product = obj("PBXFileReference", explicitFileType=wrapper, includeInIndex=0, path=f"{name}.{extension}", sourceTree="BUILT_PRODUCTS_DIR")
    products.append(product)
    bundle = "com.season.chalisa" if name == "Chalisa" else f"jp.seasonpaudel.{name.lower()}"
    settings = {**base, "PRODUCT_BUNDLE_IDENTIFIER": bundle, **extra}
    if os.environ.get("DEVELOPMENT_TEAM"):
        settings["DEVELOPMENT_TEAM"] = os.environ["DEVELOPMENT_TEAM"]
    tid = obj("PBXNativeTarget", name=name, productName=name, productType=f"com.apple.product-type.{product_type}", productReference=product, buildConfigurationList=config(settings), buildPhases=phases, buildRules=[], dependencies=[])
    targets.append(tid)
    return tid

app = target("Chalisa", "Chalisa", "application", dict(
    INFOPLIST_KEY_CFBundleDisplayName="Chalisa", INFOPLIST_KEY_LSApplicationCategoryType="public.app-category.education",
    INFOPLIST_KEY_UIApplicationSceneManifest_Generation="YES", INFOPLIST_KEY_UILaunchScreen_Generation="YES",
    INFOPLIST_KEY_UISupportedInterfaceOrientations="UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
    ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon", ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME="AccentColor",
), [("Chalisa/Resources/verses.json", "text.json"), ("../dist/audio", "folder"), ("Chalisa/Assets.xcassets", "folder.assetcatalog")], plist="Chalisa/Info.plist")
# Home Screen and Lock Screen widget. No App Group: free Personal Teams cannot sign one,
# so the widget reads only bundled content and never the app's saved progress.
widget = target("ChalisaWidget", "ChalisaWidget", "app-extension", dict(
    PRODUCT_BUNDLE_IDENTIFIER="com.season.chalisa.widget", INFOPLIST_KEY_CFBundleDisplayName="Chalisa",
    ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME="AccentColor", SKIP_INSTALL="YES",
    LD_RUNPATH_SEARCH_PATHS="$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks",
), [("Chalisa/Resources/verses.json", "text.json"), ("Chalisa/Assets.xcassets", "folder.assetcatalog")],
    shared=["Chalisa/Models.swift", "Chalisa/Palette.swift", "Chalisa/DailyPassage.swift"], plist="ChalisaWidget/Info.plist")
unit = target("ChalisaTests", "ChalisaTests", "bundle.unit-test", dict(TEST_HOST="$(BUILT_PRODUCTS_DIR)/Chalisa.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Chalisa", BUNDLE_LOADER="$(TEST_HOST)"))
ui = target("ChalisaUITests", "ChalisaUITests", "bundle.ui-testing", dict(TEST_TARGET_NAME="Chalisa"))
product_group = obj("PBXGroup", name="Products", children=products, sourceTree="<group>")
root_group = obj("PBXGroup", children=groups + [product_group], sourceTree="<group>")
project = obj("PBXProject", attributes={"BuildIndependentTargetsInParallel": "YES", "LastUpgradeCheck": "2700", "TargetAttributes": {app: {"CreatedOnToolsVersion": "27.0"}, widget: {"CreatedOnToolsVersion": "27.0"}, unit: {"TestTargetID": app}, ui: {"TestTargetID": app}}}, buildConfigurationList=config(dict(SDKROOT="iphoneos", IPHONEOS_DEPLOYMENT_TARGET="17.0", SWIFT_VERSION="5.0")), compatibilityVersion="Xcode 14.0", developmentRegion="en", knownRegions=["en", "Base"], mainGroup=root_group, productRefGroup=product_group, projectDirPath="", projectRoot="", targets=targets)
embed = obj("PBXBuildFile", fileRef=objects[widget]["productReference"], settings={"ATTRIBUTES": ["RemoveHeadersOnCopy"]})
objects[app]["buildPhases"].append(obj("PBXCopyFilesBuildPhase", buildActionMask=2147483647, dstPath="", dstSubfolderSpec=13, name="Embed Foundation Extensions", files=[embed], runOnlyForDeploymentPostprocessing=0))
objects[app]["dependencies"] = [obj("PBXTargetDependency", target=widget, targetProxy=obj("PBXContainerItemProxy", containerPortal=project, proxyType=1, remoteGlobalIDString=widget, remoteInfo="ChalisaWidget"))]
for tid in [unit, ui]:
    proxy = obj("PBXContainerItemProxy", containerPortal=project, proxyType=1, remoteGlobalIDString=app, remoteInfo="Chalisa")
    objects[tid]["dependencies"] = [obj("PBXTargetDependency", target=app, targetProxy=proxy)]

def serialize(value):
    if isinstance(value, dict): return "{\n" + "\n".join(f"{json.dumps(str(k))} = {serialize(v)};" for k, v in value.items()) + "\n}"
    if isinstance(value, list): return "(\n" + "".join(serialize(v) + ",\n" for v in value) + ")"
    return json.dumps(str(value))

project_dir = ROOT / "Chalisa.xcodeproj"
project_dir.mkdir(exist_ok=True)
(project_dir / "project.pbxproj").write_text("// !$*UTF8*$!\n" + serialize(dict(archiveVersion=1, classes={}, objectVersion=56, objects=objects, rootObject=project)) + "\n")
scheme_dir = project_dir / "xcshareddata/xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
def ref(tid, name, extension):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{tid}" BuildableName="{name}.{extension}" BlueprintName="{name}" ReferencedContainer="container:Chalisa.xcodeproj"/>'
(scheme_dir / "Chalisa.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref(app, "Chalisa", "app")}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.PosixSpawn" shouldUseLaunchSchemeArgsEnv="YES"><Testables>
<TestableReference skipped="NO" parallelizable="NO">{ref(unit, "ChalisaTests", "xctest")}</TestableReference>
<TestableReference skipped="NO" parallelizable="NO">{ref(ui, "ChalisaUITests", "xctest")}</TestableReference>
</Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref(app, "Chalisa", "app")}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref(app, "Chalisa", "app")}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(project_dir)
