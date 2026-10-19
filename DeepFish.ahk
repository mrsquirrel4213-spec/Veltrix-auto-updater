;====================================================================================================;
;
;   DeepFish BETA
;   Copyright (c) 2026 Yato. All rights reserved.
;
;   YOU MAY:
;     - Use this macro for your own personal use.
;     - Read the source and reuse PARTS of it in your own projects, provided that "Yato" is
;       credited visibly somewhere in that project's user interface.
;
;   YOU MAY NOT:
;     - Redistribute this macro, modified or unmodified, in whole or in substantial part.
;     - Publish a modified build of it, or present it as your own work.
;     - Remove, hide or alter the credits shown in the About tab.
;     - Sell it, or put it behind payment, subscription or paid access of any kind.
;
;   PORTIONS FROM OTHER PROJECTS
;     Precision/Lines mode's control method (PD steering with velocity tracking and stopping
;     distance) is adapted from IRUS IDIOTPROOF, IRUS COMET by AsphaltCake.
;       Source:  https://www.youtube.com/@AsphaltCake
;     Those portions remain subject to AsphaltCake's own terms, which permit sharing
;     modifications with attribution. The restrictions above apply to Yato's original work
;     and cannot and do not override AsphaltCake's terms for their part.
;
;     Changes made to that method in this macro: reimplemented in AutoHotkey v1; driven by
;     this macro's own GDI capture and color-calibration code; extended with an arrow-based
;     fallback for when the bar itself is not visible.
;
;   NO WARRANTY
;     Provided "as is", without warranty of any kind. Automating a game may breach its rules.
;     You use this at your own risk, and the author accepts no responsibility for any
;     consequence to your account.
;
;====================================================================================================;

#SingleInstance Force
#MaxThreadsPerHotkey 2

DFBetaVersion := "1.1.7"
FsExtraCount := 0
KbPostponeN := 0
KbUiClear := true
KbPreState := 0
KbGoodPct := ""
KbSuspect := false
KbPreFailN := 0
KbPreSkip := 0
SwStarGoneAt := 0
CastSeenN := 0
CastMissN := 0
KbMissN := 0
FsCount := 0
FsTotal := 0
FsLastName := ""
FsLastKg := ""
FsLastVal := ""
FsSeen := {}
FsPending := false
FsReqT := 0
FsWorkerPid := 0
DFModBuild := 57
DFVersion := DFVerName(DFModBuild)
DFUpdateRepo := "mrsquirrel4213-spec/auto-updater-for-my-version-of-deepfish"
DFInstallForm := "https://docs.google.com/forms/d/e/1FAIpQLSefWgHfYjr1KmIf7nr1eu7a5Am1a6pmvuSP6w6cnVWeprPIZQ/formResponse|entry.120608623"
DFInstallHook := "https://discord.com/api/webhooks/1559177033320235070/lwApqkQylZKb41cWYMwHoMeeWyLuaFe8IrWdwwCabKRh3q8HUD3ya1uCibvO5lKEKSnI"
DFKeySalt := "89a8ae69945953e706be487f26863e94"

setkeydelay, -1
setmousedelay, -1
setbatchlines, -1
SetTitleMatchMode 2

CoordMode, Tooltip, Relative
CoordMode, Pixel, Client
CoordMode, Mouse, Client


DllCall("QueryPerformanceFrequency", "Int64*", QpcFreq)
if (!QpcFreq)
	QpcFreq := 10000000
Process, Priority, , High
LineHitsFn()


ProfilesDir := A_ScriptDir . "\Profiles"
SettingsFile := A_ScriptDir . "\Settings.ini"
DefaultProfileFile := ProfilesDir . "\Default.ini"

ProfileFields := []
ProfileFields.Push( ["General","AutoLowerGraphics","true","bool"]
                  , ["General","AutoGraphicsDelay","50","num"]
                  , ["General","AutoZoomInCamera","true","bool"]
                  , ["General","AutoZoomDelay","50","num"]
                  , ["General","AutoEnableCameraMode","true","bool"]
                  , ["General","AutoCameraDelay","5","num"]
                  , ["General","AutoLookDownCamera","true","bool"]
                  , ["General","AutoLookDelay","200","num"]
                  , ["General","AutoBlurCamera","false","bool"]
                  , ["General","AutoBlurDelay","50","num"]
                  , ["General","RestartDelay","1000","num"]
                  , ["General","TimeOffset","0","num"]
                  , ["General","HideOverlay","false","bool"]
                  , ["General","PassiveAll","false","bool"]
                  , ["General","PassiveMs","500","num"]
                  , ["General","InfoPanelOn","false","bool"]
                  , ["General","FishScanOn","false","bool"]
                  , ["General","InfoPanelX","0.02","num"]
                  , ["General","InfoPanelY","0.35","num"]
                  , ["Update","AutoUpdate","false","bool"]
                  , ["Advanced","AdvancedOn","false","bool"]
                  , ["General","HoldRodCastDuration","1000","num"]
                  , ["General","WaitForBobberDelay","1000","num"]
                  , ["General","NavigationKey","\","str"]
                  , ["General","RodSlotKey","1","str"]
                  , ["General","BagSlotKey","2","str"]
                  , ["General","UnstickAfter","2","num"] )
ProfileFields.Push( ["Cast","CastMode","Normal","castmode"]
                  , ["Cast","PerfectGreenColor","0x60AA4A","str"]
                  , ["Cast","PerfectWhiteColor","0xFFFEF3","str"]
                  , ["Cast","PerfectGreenTolerance","0","num"]
                  , ["Cast","PerfectWhiteTolerance","0","num"]
                  , ["Cast","PerfectFailTimeout","20","num"]
                  , ["Cast","PerfectReleaseTiming","0","num"]
                  , ["Cast","PerfectWaitCycles","1","num"]
                  , ["Cast","SmartCast","true","bool"]
                  , ["Cast","SmartCastN","1","num"]
                  , ["Cast","AdaptiveCast","false","bool"]
                  , ["Cast","AdaptiveCastMs","150","num"] )
ProfileFields.Push( ["Shake","ShakeMode","Navigation","shakemode"]
                  , ["Shake","FishBarColorTolerance","3","num"]
                  , ["Shake","ShakeAreaLeftPct","21","num"]
                  , ["Shake","ShakeAreaRightPct","79","num"]
                  , ["Shake","ShakeAreaTopPct","25","num"]
                  , ["Shake","ShakeAreaBottomPct","88","num"]
                  , ["Shake","NavigationShakeFailsafe","30","num"]
                  , ["Shake","NavigationSpamDelay","10","num"] )
ProfileFields.Push( ["Minigame","ControlMode","Precision","controlmode"]
                  , ["Minigame","BarCalculationFailsafe","60","num"]
                  , ["Minigame","FishColor","0x434B5B","str"]
                  , ["Minigame","BarLeftColor","0xF1F1F1","str"]
                  , ["Minigame","BarRightColor","0xF1F1F1","str"]
                  , ["Minigame","BarColorTolerance","3","num"]
                  , ["Minigame","ArrowColor","0x848587","str"]
                  , ["Minigame","ArrowColorTolerance","3","num"]
                  , ["Minigame","StabilizerLoop","10","num"]
                  , ["Minigame","SideBarRatio","0.8","num"]
                  , ["Minigame","SideBarWaitMultiplier","4.5","num"]
                  , ["Minigame","SpecialRod","None","specialrod"]
                  , ["Minigame","RemembranceMode","Living","remembrancemode"]
                  , ["Minigame","NoteColor","0xB2CFFF","str"]
                  , ["Minigame","NoteColorTolerance","15","num"]
                  , ["Minigame","NoteBias","100","num"]
                  , ["Minigame","NoteRegionHeight","1000","num"]
                  , ["Minigame","NoteHandoff","50","num"]
                  , ["Minigame","LullRadiusPct","16","num"]
                  , ["Minigame","LullPivotUp","26","num"]
                  , ["Minigame","LullLightLum","90","num"]
                  , ["Minigame","LullArmDelta","45","num"]
                  , ["Minigame","LullTrigPct","10","num"]
                  , ["Minigame","LullClearMs","100","num"]
                  , ["Minigame","LullMinDeg","4","num"]
                  , ["Minigame","ReelMinHold","200","num"]
                  , ["Minigame","ReelMinRelease","200","num"]
                  , ["Minigame","ManiaLead","45","num"] )
ProfileFields.Push( ["Rods","TryhardBarColors","","str"]
				  , ["Rods","TryhardBarTol","20","num"]
				  , ["Rods","TryhardFishColors","","str"]
				  , ["Rods","TryhardFishTol","14","num"]
				  , ["Rods","TryhardTrackColors","","str"]
				  , ["Rods","TryhardTrackTol","20","num"]
				  , ["Rods","CastboundBarColors","","str"]
				  , ["Rods","CastboundBarTol","20","num"]
				  , ["Rods","CastboundFishColors","0x5522A3","str"]
				  , ["Rods","CastboundFishTol","20","num"]
				  , ["Rods","CastboundTrackColors","","str"]
				  , ["Rods","CastboundTrackTol","20","num"]
				  , ["Rods","HalibutPlayMinigame","true","bool"]
				  , ["Rods","SwClickSigns","true","bool"]
				  , ["Rods","SwFastClicks","false","bool"]
				  , ["Rods","SwRetryFails","false","bool"]
				  , ["Rods","SwPreset","Normal","str"]
				  , ["Rods","SwMaxSigns","false","bool"]
				  , ["Rods","SwAllSigns","false","bool"]
				  , ["Rods","SwWaitN","12","num"]
				  , ["Rods","SwSignsFirst","false","bool"]
				  , ["Rods","SwPassive","false","bool"]
				  , ["Rods","SwPassiveMs","500","num"]
				  , ["Rods","SwPassiveHide","false","bool"]
				  , ["Rods","SwGuessOn","false","bool"]
				  , ["Rods","SwGuessPts","","str"]
				  , ["Rods","SwGuessLit","-1","num"]
				  , ["Rods","SwGuessUnlit","-1","num"]
				  , ["Rods","SwGuessWait","100","num"]
				  , ["Rods","SwGuessLastN","3","num"]
				  , ["Rods","SwGuessGuess","true","bool"]
				  , ["Rods","StellarBarColors","0x55446D","str"]
				  , ["Rods","StellarBarTol","26","num"]
				  , ["Rods","StellarFishColors","0xAFDAE8","str"]
				  , ["Rods","StellarFishTol","22","num"]
				  , ["Rods","StellarHeadColors","0xFFFFFF","str"]
				  , ["Rods","StellarHeadTol","30","num"]
				  , ["Rods","SwColsNormal","","str"]
				  , ["Rods","SwColsOuija","","str"] )
ProfileFields.Push( ["Tuning","StableRightMultiplier","2.1","num"]
                  , ["Tuning","StableRightDivision","1.4","num"]
                  , ["Tuning","StableLeftMultiplier","1.1","num"]
                  , ["Tuning","StableLeftDivision","1.0","num"]
                  , ["Tuning","UnstableRightMultiplier","2.4","num"]
                  , ["Tuning","UnstableRightDivision","1.5","num"]
                  , ["Tuning","UnstableLeftMultiplier","1.3","num"]
                  , ["Tuning","UnstableLeftDivision","1.1","num"]
                  , ["Tuning","RightAnkleBreakMultiplier","1","num"]
                  , ["Tuning","LeftAnkleBreakMultiplier","0.9","num"]
                  , ["Tuning","Kp","0.5","num"]
                  , ["Tuning","Kd","0.3","num"]
                  , ["Tuning","VelocitySmoothing","0.2","num"]
                  , ["Tuning","StoppingDistanceMultiplier","3.0","num"] )
ProfileFields.Push( ["Keeper","KeeperAuto","false","bool"]
                  , ["Keeper","KeeperEveryCatches","20","num"]
                  , ["Keeper","KeeperRecharges","1","num"]
                  , ["Keeper","KeeperRelicKey","","str"]
                  , ["Keeper","KeeperInvKey","g","str"]
                  , ["Keeper","KeeperEnchantX","0","num"]
                  , ["Keeper","KeeperEnchantY","0","num"]
                  , ["Keeper","KeeperConfirmX","0","num"]
                  , ["Keeper","KeeperConfirmY","0","num"]
                  , ["Keeper","KeeperBetweenDelay","2000","num"]
                  , ["Keeper","KeeperStepDelay","100","num"]
                  , ["Keeper","KeeperOpenDelay","100","num"]
                  , ["Keeper","KeeperPreDelay","0","num"]
                  , ["Keeper","KeeperOcrOn","false","bool"]
                  , ["Keeper","KeeperOcrEvery","1","num"]
                  , ["Keeper","KeeperLineX","0","num"]
                  , ["Keeper","KeeperLineY1","0","num"]
                  , ["Keeper","KeeperLineY2","0","num"]
                  , ["Keeper","KeeperLineColor","-1","num"]
                  , ["Keeper","KeeperLineTol","40","num"]
                  , ["Keeper","KeeperAutoBar","true","bool"]
                  , ["Keeper","KeeperAutoPct","15","num"] )
ProfileFields.Push( ["Aquarium","AquariumAuto","false","bool"]
                  , ["Aquarium","AquariumEveryMin","63","num"]
                  , ["Aquarium","AquariumFoodCount","12","num"]
                  , ["Aquarium","AquariumMaxBuys","8","num"]
                  , ["Aquarium","AquariumStepDelay","320","num"]
                  , ["Aquarium","AquariumOpenDelay","1500","num"]
                  , ["Aquarium","AquariumScrollSteps","14","num"] )
ProfileFields.Push( ["Totem","TotemAuto","false","bool"]
                  , ["Totem","TotemPollSec","20","num"]
                  , ["Totem","TotemActDelay","2500","num"]
                  , ["Totem","TotemKeySundial","","str"]
                  , ["Totem","TotemKeyClearcast","","str"]
                  , ["Totem","TotemKeyTempest","","str"]
                  , ["Totem","TotemKeyWindset","","str"]
                  , ["Totem","TotemKeySmokescreen","","str"]
                  , ["Totem","TotemKeyEclipse","","str"]
                  , ["Totem","TotemKeyAurora","","str"]
                  , ["Totem","TotemKeyStarfall","","str"]
                  , ["Totem","TotemKeyShiny","","str"]
                  , ["Totem","TotemKeySparkling","","str"]
                  , ["Totem","TotemKeyMutation","","str"]
                  , ["Totem","TotemSel1","Aurora","totemsel"]
                  , ["Totem","TotemSel2","None","totemsel"]
                  , ["Totem","TotemSel3","None","totemsel"] )
ProfileFields.Push( ["Misc","PogoOn","false","bool"]
                  , ["Misc","PogoHotkey","F6","str"]
                  , ["Misc","PogoKey","9","str"]
                  , ["Misc","PogoWait","600","num"]
                  , ["Misc","PogoCoilKey","2","str"]
                  , ["Misc","PogoCoilWait","0","num"]
                  , ["Misc","PogoJumpKey","Space","str"]
                  , ["Misc","PogoHold","30","num"] )

gosub, EnsureConfigFiles
gosub, LoadSettingsFile
gosub, LoadActiveProfile
gosub, FirstRunGate
gosub, DFAccessInit

MacroRunning := false
MacroPaused := false
NoteHoldAt := 0
NoteNeeded := false
NoteFresh := true
NoteBlitAt := 0
NoteRefreshMs := 55
NoteMissAt := 0
NoteMissN := 0
TargetIsNote := false
NoteAcc := 0
CastHolding := false
MgInPlay := false
MacroPreview := false
RunKeysArmed := false
BarLostAt := 0
BarWOutFirst := 0
BarWCal := 0
SectionBuilt := {}
ControlModeDdl := 0
NoteIndep := false
NoteOriginX := 0
NoteOriginY := 0
MgScore := 0
MgConf := 0
MgSawBar := false
MgSawFish := false
MgSawArrow := false
MgLastSig := -1
MgStaticN := 0
MgStaticAt := 0
BarSizeBadN := 0
BarSizePend := 0
BarSizePendN := 0
HudBuilt := false
HudGpOk := false
HudGdipToken := 0
hHudDC := 0
hHudBM := 0
hHudOldBM := 0
pHudBits := 0
pHudGfx := 0
pHudBmp := 0
HudSurfW := 0
HudSurfH := 0
HudH := 34
HudNoteX := -1
HudNote2X := -1
HudDirty := true
HudLastKey := ""
HudPrevT := 0
BarWTrust := 0
HudWRing := []
HudWMed := 0
; ==============================================================================================
TargetSection := ""
MgBlocks := {}
MgVisible := {}
MgAllCtrls := []
AllManaged := []
VisibleCtrls := []
CtrlBaseX := {}
CtrlBaseY := {}
CtrlW := {}
CtrlH := {}
CtrlRgnR := {}
CtrlClip := {}
SbTrack := 0
SbThumb := 0
SbTrackH := 0
SbThumbH := 0
SbShown := -1
ContentTopEdge := 120
SecTopEdge := 58
DpiF := (A_ScreenDPI > 0) ? (A_ScreenDPI / 96) : 1
SecScroll := {}
SecMaxScroll := 0
DetTesting := false
CardRects := []
hRunStatus := 0
ColorListCache := {}
ColorListCacheN := 0

CMTargetKeys := ["FishColor","BarLeftColor","BarRightColor","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
CMTargetLabel := {FishColor: "Fish line", BarLeftColor: "Bar - left end", BarRightColor: "Bar - right end"
	, ArrowColor: "Bar arrow", NoteColor: "Falling note", PerfectGreenColor: "Cast bar - green", PerfectWhiteColor: "Cast bar - white"}
CMTargetSection := {FishColor: "Minigame", BarLeftColor: "Minigame", BarRightColor: "Minigame"
	, ArrowColor: "Minigame", NoteColor: "Minigame", PerfectGreenColor: "Cast", PerfectWhiteColor: "Cast"}
CMTargetHint := {FishColor: "The thin marker that slides along the bar —`nthe fish you are chasing."
	, BarLeftColor: "The LEFT end of the reeling bar.`nAdd every shade it takes if the bar`nchanges color as it fills."
	, BarRightColor: "The RIGHT end of the reeling bar.`nAdd every shade it takes if the bar`nchanges color as it fills."
	, ArrowColor: "The small arrow drawn inside the`nreeling bar."
	, NoteColor: "A falling note.`nPinions Aria only."
	, PerfectGreenColor: "The green perfect-cast marker on`nthe cast power bar."
	, PerfectWhiteColor: "The white fill of the cast power bar."}
CMShortLabel := {FishColor: "Fish line", BarLeftColor: "Bar left", BarRightColor: "Bar right"
	, ArrowColor: "Arrow", NoteColor: "Note", PerfectGreenColor: "Cast green", PerfectWhiteColor: "Cast white"}
CMSel := "FishColor"
CMRowMax := 9
CMTargetLabel.TryhardBarColors := "Tryhard bar"
CMTargetLabel.TryhardFishColors := "Tryhard fish"
CMTargetLabel.TryhardTrackColors := "Tryhard track"
CMTargetLabel.CastboundBarColors := "Castbound bar"
CMTargetLabel.CastboundFishColors := "Castbound sword"
CMTargetLabel.CastboundTrackColors := "Castbound track"
CMShortLabel.TryhardBarColors := "Bar"
CMShortLabel.TryhardFishColors := "Fish"
CMShortLabel.TryhardTrackColors := "Track"
CMShortLabel.CastboundBarColors := "Bar"
CMShortLabel.CastboundFishColors := "Sword"
CMShortLabel.CastboundTrackColors := "Track"
for CMk, CMv in ["TryhardBarColors","TryhardFishColors","TryhardTrackColors","CastboundBarColors","CastboundFishColors","CastboundTrackColors"]
	CMTargetSection[CMv] := "Rods"
CMTargetHint.TryhardBarColors := "Only if the bar is never picked up. Click the`nbar while the fish is inside it (bright red)`nand while it is outside (dark red)."
CMTargetHint.TryhardFishColors := "Only if the fish is never found. Click the`ndark marker that sticks out above the bar."
CMTargetHint.TryhardTrackColors := "Only if the bar is still not found. Click`nthe dark red track beside the bar."
CMTargetHint.CastboundBarColors := "Only helps if the bar looks very dark on`nyour screen. Pick the track and the sword`nfirst."
CMTargetHint.CastboundFishColors := "Only if the fish is never found. Click the`npurple sword marker. 0x5522A3 is the normal`ncolor and changes nothing."
CMTargetHint.CastboundTrackColors := "Only if the minigame is never detected.`nClick the purple track the bar slides on."
CMTargetLabel.StellarBarColors := "Stellarwave bar"
CMTargetLabel.StellarFishColors := "Stellarwave fish"
CMTargetLabel.StellarHeadColors := "Stellarwave fish head"
CMShortLabel.StellarBarColors := "Bar"
CMShortLabel.StellarFishColors := "Fish"
CMShortLabel.StellarHeadColors := "Fish head"
for CMk, CMv in ["StellarBarColors","StellarFishColors","StellarHeadColors"]
	CMTargetSection[CMv] := "Rods"
CMTargetHint.StellarBarColors := "The thin dark purple frame around the bar,`nnot the colorful inside. 0x55446D is the`nnormal color."
CMTargetHint.StellarFishColors := "The light blue line of the fish on the bar.`n0xAFDAE8 is the normal color."
CMTargetHint.StellarHeadColors := "The white note head of the fish, just above`nthe bar. 0xFFFFFF is the normal color."
gosub, CMApplyTargets
MiniTab := "Setup"
MiniTop := 162
MiniTabSetupH := 0
MiniTabColorsH := 0
FreezeActive := false
FreezeTarget := ""
FreezeMode := "add"
FreezePicked := ""

HudZoneShown := false
NoteNextX := -1
NoteNextY := -1
NoteLockY := -1
BarLiveL := -1
BarLiveR := -1
BarLiveMiss := 0
BarWLive := -1
BarLiveOnlyAt := 0
BarWidthTrusted := true
BarWOutN := 0
CastBarL := -1
CastBarW := 0
CastFishX := -1
CastScanned := false
CastBlindN := 0
CastPrevL := -1
CastPrevW := -1
CastPrevF := -1
CastSameN := 0
CastSameT := 0
CastStatic := false
RemWhiteX := -1
RemBlackX := -1
RemTargetX := -1
CtrAcc := 0
CtrBias := 0
RemScanned := false
RemFound := false
RemBarScanned := false
RemBarFound := false
RemBarL := -1
RemBarW := 0
RemBarRing := []
MiguFishX := -1
MiguLastX := -1
MiguScanned := false
MiguFound := false
MiguBarScanned := false
MiguBarFound := false
MiguBarL := -1
MiguBarW := 0
TryScanned := false
TryFound := false
TryFishX := -1
TryBarL := -1
TryBarW := 0
if (RemembranceMode = "")
	RemembranceMode := "Living"
CastFound := false
NoteHoldX := -1
LullFrames := 0
LullCalN := 0
LullR := 0
LullSecN := 0
LullCalLt := []
LullCalDk := []
LullCalLs := []
LullBg := []
LullSecA := []
LullSecB := []
LullArmA := []
LullClrT := []
LullActive := false
LullSeen := false
LullGoneN := 0
LullClicks := 0
LullHitSec := 0
NoteAllX := []
NoteAllY := []
NoteAllN := 0
TotemEvt := []
TotemCool := {}
TotemAssume := {}
TotemAssumeMiss := {}
TotemAssumeSlot := {}
TotemAssumeCnt := {}
TotemAssumeSrc := {}
TotemAssumeAt := {}
TotemTaken := {}
TotemLastPop := ""
TotemLastPopSigs := ""
TotemLastPopUntil := 0
TotemCyclePopped := ","
TotemCheckNo := 0
TotemTime := ""
TotemWeather := ""
AqNextTick := 0
KbCatches := 0
KbOcrCatches := 0
KbBusy := false
KbStatus := "idle"
KbLastResult := ""
AqBusy := false
AqHoverOk := false
AqStatus := "idle"
AqLastResult := ""
AqBtnN := 0
AqBtnCX := []
AqBtnCY := []
AqBtnKind := []
AqBuys := 0
AqUses := 0
AqCardPitch := 0
TotemEvents := ""
TotemEvtSigs := ""
TotemDbg := ""
TotemLastCheck := 0
TotemWantTime := ""
WhStartTick := 0
WhCatches := 0
WhLastCatchTick := 0
WhLastSummary := 0
WhStalled := false
PausedMs := 0
AutoRefocus := true
LastAutoStop := 0
PCLastGoodY := -1
HotkeysArmed := false
CastFailCount := 0
DarkHoldN := 0
DarkFlashing := false
TqResetAll()
BelPrevF := [0,0]
BelPrevB := [0,0]
BelPrevT := [0,0]
BelVel := [0,0]
BelBVel := [0,0]
BelDown := [false,false]
BelSide := [0,0]
BelAcc := [0,0]
BelBias := [0,0]
BelA := [0,0]
BelB := [0,0]
BelF := [-1,-1]
BelOK := [false,false]
DutyAvg := 0.5
DarkAcc := 0
settimer, HotkeyWatch, 500

Hotkey, % "$" . StartStopKey, HotkeyToggle, Off
Hotkey, % "$" . ReloadKey, HotkeyReload, Off
Hotkey, % "$" . ExitKey, HotkeyExit, Off
ForceReEquip := false
RodEquippedOnce := false
Hotkey, $F9, FreezePickHotkey, On
GroupAdd, RobloxGrp, ahk_exe RobloxPlayerBeta.exe
GroupAdd, RobloxGrp, ahk_exe Windows10Universal.exe
PogoHkNow := ""
gosub, PogoApplyHotkey

Menu, Tray, Tip, DeepFish BETA
Menu, Tray, Add, Show DeepFish, ShowGuiFromTray
Menu, Tray, Default, Show DeepFish
Menu, Tray, Click, 1

gosub, BuildGui

return

;====================================================================================================;

ResolveRoblox:
RobloxHwnd := 0
WinGet, RobloxHwnd, ID, ahk_exe RobloxPlayerBeta.exe
if (!RobloxHwnd)
	{
	SetTitleMatchMode, 3
	WinGet, RobloxHwnd, ID, Roblox
	SetTitleMatchMode, 2
	}
return

;====================================================================================================;

Calculations:
if (!RobloxHwnd)
	gosub, ResolveRoblox
RobloxClientRect(RobloxHwnd, WindowLeft, WindowTop, WindowWidth, WindowHeight)

AqNavX := (WindowWidth // 2) + 101
AqNavY := 29

CameraCheckLeft := WindowWidth/2.8444
CameraCheckRight := WindowWidth/1.5421
CameraCheckTop := WindowHeight/1.28
CameraCheckBottom := WindowHeight

ClickShakeLeft := WindowWidth * ClampPct(ShakeAreaLeftPct, 0, 99) / 100
ClickShakeRight := WindowWidth * ClampPct(ShakeAreaRightPct, 1, 100) / 100
ClickShakeTop := WindowHeight * ClampPct(ShakeAreaTopPct, 0, 99) / 100
ClickShakeBottom := WindowHeight * ClampPct(ShakeAreaBottomPct, 1, 100) / 100
if (ClickShakeRight <= ClickShakeLeft)
	ClickShakeRight := ClickShakeLeft + 1
if (ClickShakeBottom <= ClickShakeTop)
	ClickShakeBottom := ClickShakeTop + 1

if (SpecialRod = "Bellona's Waraxe")
	{
	FishBarLeft := WindowWidth * 0.05
	FishBarRight := WindowWidth * 0.95
	}
else
	{
	FishBarLeft := WindowWidth/3.3160
	FishBarRight := WindowWidth/1.4317
	}
FishBarTop := WindowHeight/1.1871
FishBarBottom := WindowHeight/1.1512

if (SpecialRod = "Remembrance")
	{
	FishBarTop := WindowHeight/1.2318
	FishBarBottom := WindowHeight/1.1862
	}
if (SpecialRod = "Stellarwave Melody")
	{
	FishBarLeft := WindowWidth * 0.22
	FishBarRight := WindowWidth * 0.78
	FishBarTop := WindowHeight * 0.795
	FishBarBottom := WindowHeight * 0.945
	}
TrackLeft := FishBarLeft
TrackRight := FishBarRight
if (SpecialRod = "Stellarwave Melody")
	{
	TrackLeft := WindowWidth * 0.245
	TrackRight := WindowWidth * 0.755
	}

FishBarTooltipHeight := WindowHeight/1.0626

gosub, SetupCapture

ResolutionScaling := 2560/WindowWidth

LookDownX := WindowWidth/2
LookDownY := WindowHeight/4

runtimeS := 0
runtimeM := 0
runtimeH := 0

TooltipX := WindowWidth/20
Tooltip1 := (WindowHeight/2)-(20*9)
Tooltip2 := (WindowHeight/2)-(20*8)
Tooltip3 := (WindowHeight/2)-(20*7)
Tooltip4 := (WindowHeight/2)-(20*6)
Tooltip5 := (WindowHeight/2)-(20*5)
Tooltip6 := (WindowHeight/2)-(20*4)
Tooltip7 := (WindowHeight/2)-(20*3)
Tooltip8 := (WindowHeight/2)-(20*2)
Tooltip9 := (WindowHeight/2)-(20*1)
Tooltip10 := (WindowHeight/2)
Tooltip11 := (WindowHeight/2)+(20*1)
Tooltip12 := (WindowHeight/2)+(20*2)
Tooltip13 := (WindowHeight/2)+(20*3)
Tooltip14 := (WindowHeight/2)+(20*4)
Tooltip15 := (WindowHeight/2)+(20*5)
Tooltip16 := (WindowHeight/2)+(20*6)
Tooltip17 := (WindowHeight/2)+(20*7)
Tooltip18 := (WindowHeight/2)+(20*8)
Tooltip19 := (WindowHeight/2)+(20*9)
Tooltip20 := (WindowHeight/2)+(20*10)

if (DetTesting)
	goto CalcTipsDone

tooltip, Made By Yato, %TooltipX%, %Tooltip1%, 1
tooltip, Runtime: 0h 0m 0s, %TooltipX%, %Tooltip2%, 2


if (DetTesting)
	goto CalcTipsDone
gosub, RefreshHints

if (AutoLowerGraphics == true)
	{
	tooltip, AutoLowerGraphics: true, %TooltipX%, %Tooltip8%, 8
	}
else
	{
	tooltip, AutoLowerGraphics: false, %TooltipX%, %Tooltip8%, 8
	}
	
if (AutoEnableCameraMode == true)
	{
	tooltip, AutoEnableCameraMode: true, %TooltipX%, %Tooltip9%, 9
	}
else
	{
	tooltip, AutoEnableCameraMode: false, %TooltipX%, %Tooltip9%, 9
	}
	
if (AutoZoomInCamera == true)
	{
	tooltip, AutoZoomInCamera: true, %TooltipX%, %Tooltip10%, 10
	}
else
	{
	tooltip, AutoZoomInCamera: false, %TooltipX%, %Tooltip10%, 10
	}
	
if (AutoLookDownCamera == true)
	{
	tooltip, AutoLookDownCamera: true, %TooltipX%, %Tooltip11%, 11
	}
else
	{
	tooltip, AutoLookDownCamera: false, %TooltipX%, %Tooltip11%, 11
	}
	
if (AutoBlurCamera == true)
	{
	tooltip, AutoBlurCamera: true, %TooltipX%, %Tooltip12%, 12
	}
else
	{
	tooltip, AutoBlurCamera: false, %TooltipX%, %Tooltip12%, 12
	}

tooltip, Navigation Key: "%NavigationKey%", %TooltipX%, %Tooltip14%, 14

if (ShakeMode == "Disabled")
	{
	tooltip, Shake Mode: "Disabled", %TooltipX%, %Tooltip16%, 16
	}
else
	{
	tooltip, Shake Mode: "Navigation", %TooltipX%, %Tooltip16%, 16
	}
CalcTipsDone:
return

;====================================================================================================;

runtime:
runtimeS++
if (runtimeS >= 60)
	{
	runtimeS := 0
	runtimeM++
	}
if (runtimeM >= 60)
	{
	runtimeM := 0
	runtimeH++
	}


if WinActive("ahk_id " . RobloxHwnd)
	{
	RunDbg := MacroRunning ? "Y" : "N"
	KeyDbg := HotkeysArmed ? "armed" : "OFF"
	tooltip, Runtime: %runtimeH%h %runtimeM%m %runtimeS%s | Running:%RunDbg% Keys:%KeyDbg%, %TooltipX%, %Tooltip2%, 2
	gosub, RefreshHints
	}
else if (PasIdle())
	{
	; passive mode waiting for a minigame: you can be in another window - nothing is pressed until one shows up,
	; then Roblox is brought back to play it
	tooltip, Runtime: %runtimeH%h %runtimeM%m %runtimeS%s | Passive - Roblox is in the background, %TooltipX%, %Tooltip2%, 2
	}
else
	{
	if (!CastHolding)
		send {lbutton up}
	send {rbutton up}
	send {shift up}
	PrecisionDown := false
	MacroPaused := true
	PausedMs := 0
	while (MacroRunning and !WinActive("ahk_id " . RobloxHwnd))
		{
		if (!WinExist("ahk_id " . RobloxHwnd))
			{
			gosub, ResolveRoblox
			if (!RobloxHwnd)
				{
				tooltip, Waiting for the Roblox window to come back..., %TooltipX%, %Tooltip2%, 2
				Sleep, % Tm(TA("winback", 1000))
				continue
				}
			}
		WinActivate, ahk_id %RobloxHwnd%
		WinWaitActive, ahk_id %RobloxHwnd%, , 1
		PausedMs := PausedMs + 100
		tooltip, Reclaiming focus - Roblox was not in front, %TooltipX%, %Tooltip2%, 2
		if (!WinActive("ahk_id " . RobloxHwnd))
			Sleep, % Tm(TA("winfocus", 100))
		}
	MacroPaused := false
	if (!MacroRunning)
		goto Idle
	}
return

;====================================================================================================;

HotkeyToggle:

if (MacroRunning)
	goto ToggleMacro
if WinActive("DeepFish BETA")
	return
goto ToggleMacro

HotkeyReload:
if (MacroRunning)
	goto DoReload
if WinActive("DeepFish BETA")
	return
goto DoReload

HotkeyExit:
if (MacroRunning)
	goto DoExit
if WinActive("DeepFish BETA")
	return
goto DoExit

ToggleMacro:
if (!MacroRunning and DFLocked)
	{
	MsgBox, 0x1030, DeepFish, %DFLockReason%
	return
	}
if (!MacroRunning and !ReadThisAccepted)
	{
	gosub, ReadThisLockedNotice
	return
	}
if (MacroRunning)
	{
	MacroRunning := false
	MacroPreview := false
	GuiControl, 1:, StartStopDisplay, ▶ Start
	gosub, RefreshRunChip
	settimer, runtime, off
	settimer, NavigationShakeFailsafe, off
	settimer, BarCalculationFailsafe, off
	send {lbutton up}
	send {rbutton up}
	send {shift up}
	StopSweepTicks := 0
	settimer, StopSweep, 25
	gosub, StopSweep
	return
	}
MacroRunning := true
LastAutoStop := 0
RodEquippedOnce := false
KbCatches := 0
KbOcrCatches := 0
KbBusy := false
AqNextTick := 0
AqBusy := false
WhStartTick := A_TickCount
WhLastSummary := A_TickCount
GuiControl, 1:, StartStopDisplay, ⏹ Stop
gosub, RefreshRunChip
goto StartMacroFlow

PreviewOrToggle:
if (MacroRunning)
	{
	gosub, ToggleMacro
	return
	}

if (!ReadThisAccepted)
	{
	gosub, ReadThisLockedNotice
	return
	}

if (LastAutoStop and (A_TickCount - LastAutoStop) < 2500)
	{
	LastAutoStop := 0
	gosub, Idle
	return
	}
LastAutoStop := 0

gosub, ResolveRoblox
if (!RobloxHwnd)
	{
	msgbox, 4144, DeepFish, Could not find the Roblox game window. Make sure Roblox is running, then try again.
	return
	}
WinActivate, ahk_id %RobloxHwnd%
WinWaitActive, ahk_id %RobloxHwnd%, , 2
WinMaximize, ahk_id %RobloxHwnd%

gosub, Calculations
MacroPreview := true
gosub, ArmHotkeys
if (!GuiKeepOpen)
	Gui, Hide

return

HotkeyWatch:
if (FreezeActive)
	return
if (!WinExist("DeepFish BETA"))
	gosub, ArmHotkeys
gosub, SyncRunKeys
return

ArmHotkeys:
if (!HotkeysArmed)
	{
	Hotkey, % "$" . StartStopKey, On
	HotkeysArmed := true
	}
gosub, SyncRunKeys
return

SyncRunKeys:
MacroLive := (HotkeysArmed or MacroRunning)
if (MacroLive and !RunKeysArmed)
	{
	Hotkey, % "$" . ReloadKey, On
	Hotkey, % "$" . ExitKey, On
	RunKeysArmed := true
	}
else if (!MacroLive and RunKeysArmed)
	{
	Hotkey, % "$" . ReloadKey, Off
	Hotkey, % "$" . ExitKey, Off
	RunKeysArmed := false
	}
return

DisarmHotkeys:
if (HotkeysArmed)
	{
	Hotkey, % "$" . StartStopKey, Off
	HotkeysArmed := false
	}
gosub, SyncRunKeys
return

DoReload:
MacroRunning := false
send {lbutton up}
send {rbutton up}
send {shift up}
reload

DoExit:
MacroRunning := false
send {lbutton up}
send {rbutton up}
send {shift up}
exitapp

;====================================================================================================;

StartMacroFlow:

TotemLastCheck := 0
TotemCool := {}
TotemLastPop := ""
WhStartTick := A_TickCount
WhCatches := 0
FsExtraCount := 0
FsGroups := []
FsDone := []
FsCount := 0
FsTotal := 0
FsLastName := ""
FsLastKg := ""
FsLastVal := ""
FsSeen := {}
WhLastCatchTick := 0
WhLastSummary := A_TickCount
WhStalled := false
WhEvent("start")
settimer, WhTick, 30000
send {lbutton up}
send {rbutton up}
send {shift up}

gosub, ResolveRoblox
if (!RobloxHwnd)
	{
	MacroRunning := false
	msgbox, 4144, DeepFish, Could not find the Roblox game window. Make sure Roblox is running, then try again.
	return
	}
WinActivate, ahk_id %RobloxHwnd%
WinWaitActive, ahk_id %RobloxHwnd%, , 2
WinMaximize, ahk_id %RobloxHwnd%

gosub, Calculations
settimer, runtime, 1000

gosub, RefreshHints

tooltip, , , , 6
tooltip, , , , 10
tooltip, , , , 11
tooltip, , , , 12
tooltip, , , , 14
tooltip, , , , 16

tooltip, Current Task: AutoLowerGraphics, %TooltipX%, %Tooltip7%, 7
tooltip, F10 Count: 0/20, %TooltipX%, %Tooltip9%, 9
f10counter := 0
if (AutoLowerGraphics == true)
	{
	send {shift}
	tooltip, Action: Press Shift, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoGraphicsDelay)
	send {shift down}
	tooltip, Action: Hold Shift, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoGraphicsDelay)
	loop, 20
		{
		f10counter++
		tooltip, F10 Count: %f10counter%/20, %TooltipX%, %Tooltip9%, 9
		send {f10}
		tooltip, Action: Press F10, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(AutoGraphicsDelay)
		}
	send {shift up}
	tooltip, Action: Release Shift, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoGraphicsDelay)
	}

tooltip, Current Task: AutoZoomInCamera, %TooltipX%, %Tooltip7%, 7
tooltip, Scroll In: 0/20, %TooltipX%, %Tooltip9%, 9
tooltip, Scroll Out: 0/1, %TooltipX%, %Tooltip10%, 10
scrollcounter := 0
if (AutoZoomInCamera == true and CastMode != "Perfect")
	{
	Sleep, % Tm(AutoZoomDelay)
	loop, 20
		{
		scrollcounter++
		tooltip, Scroll In: %scrollcounter%/20, %TooltipX%, %Tooltip9%, 9
		send {wheelup}
		tooltip, Action: Scroll In, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(AutoZoomDelay)
		}
	send {wheeldown}
	tooltip, Scroll Out: 1/1, %TooltipX%, %Tooltip10%, 10
	tooltip, Action: Scroll Out, %TooltipX%, %Tooltip8%, 8
	ZoomSettleDelay := AutoZoomDelay*5
	Sleep, % Tm(ZoomSettleDelay)
	}
	
tooltip, , , , 10

tooltip, Current Task: AutoEnableCameraMode, %TooltipX%, %Tooltip7%, 7
tooltip, Right Count: 0/10, %TooltipX%, %Tooltip9%, 9
rightcounter := 0
CamModeOn := (AutoEnableCameraMode and !(TotemAuto or AquariumAuto or KeeperAuto))
if (CamModeOn == true)
	{
	PixelSearch, , , CameraCheckLeft, CameraCheckTop, CameraCheckRight, CameraCheckBottom, 0xFFFFFF, 0, Fast
	if (ErrorLevel == 0)
		{
		Sleep, % Tm(AutoCameraDelay)
		send {2}
		tooltip, Action: Presss 2, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(AutoCameraDelay)
		send {1}
		tooltip, Action: Press 1, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(AutoCameraDelay)
		send {%NavigationKey%}
		tooltip, Action: Press %NavigationKey%, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(AutoCameraDelay)
		loop, 10
			{
			rightcounter++
			tooltip, Right Count: %rightcounter%/10, %TooltipX%, %Tooltip9%, 9
			send {right}
			tooltip, Action: Press Right, %TooltipX%, %Tooltip8%, 8
			Sleep, % Tm(AutoCameraDelay)
			}
		send {enter}
		tooltip, Action: Press Enter, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(AutoCameraDelay)
		}
	}

RestartMacro:

if (!MacroRunning)
	goto Idle

if (SwPressK)
	SwPressEnd()
SwWantK := 0
; in passive mode you may be in another window - do not send it stray button-ups
if (!PasIdle() or WinActive("ahk_id " . RobloxHwnd))
	{
	send {lbutton up}
	send {rbutton up}
	}
if (SwPreK)
	{
	SwPreEnd("restart")
	while (SwParkAt and SwParkWait())
		Sleep, % Tm(5)
	}

if (KeeperAuto and !KbBusy)
	{
	KbHandled := false
	KbDue := false
	if (KeeperAutoBar and KbPreState)
		{
		; read fine while the bobber was out - nothing to wait for here
		KbHandled := true
		KbPreState := 0
		}
	else if (KeeperAutoBar or KeeperOcrOn)
		{
		if (KbOcrCatches >= ((Round(KeeperOcrEvery) < 1) ? 1 : Round(KeeperOcrEvery)))
			{
			KbOcrCatches := 0
			KbHandled := false
			if (KeeperAutoBar)
				{
				KbAutoAt := KeeperAutoPct
				if KbAutoAt is not number
					KbAutoAt := 15
				gosub, KbWaitUiClear
				KbFound := false
				Loop 8
					{
					if (KbAutoRead(KbPct))
						{
						KbFound := true
						break
						}
					Sleep, 120
					}
				KbHandled := true
				if (KbFound)
					{
					KbMissN := 0
					if (KbPct < KbAutoAt + 4)
						{
						if (KbAutoReadStable(KbPct2, 3))
							KbPct := KbPct2
						if (KbPct < KbAutoAt)
							{
							; a moment later it must still read low - one odd frame never starts a recharge
							Sleep, 300
							KbDue := (KbAutoReadStable(KbPct3, 3) and KbPct3 < KbAutoAt)
							}
						}
					KbOcrLast := "power bar " . Round(KbPct, 1) . "%"
					if (!KbDue and KbPct >= KbAutoAt)
						{
						KbGoodPct := KbPct
						KbSuspect := false
						}
					else if (KbDue and KbGoodPct != "" and KbGoodPct - KbPct > 30 and !KbSuspect)
						{
						; the bar cannot drop that far in one catch - almost always a misread, so confirm next catch
						KbSuspect := true
						KbDue := false
						KbOcrCatches := 9999
						KbOcrLast .= " - big drop from " . Round(KbGoodPct) . "%, checking again next catch"
						}
					}
				else
					{
					; not seen this time (UI fading, popup, menu) - skip, do NOT fall back to counting catches
					KbMissN := KbMissN + 1
					KbOcrLast := "power bar not found (" . KbMissN . "x in a row)"
					if (KbMissN >= 10 and !KeeperOcrOn)
						KbDue := (KbCatches >= Round(KeeperEveryCatches))
					}
				}
			if (!KbHandled and !KeeperOcrOn)
				KbDue := (KbCatches >= Round(KeeperEveryCatches))
			}
		}
	if (KeeperOcrOn and !KbHandled)
		{
		if (KeeperAutoBar or KbOcrCatches >= ((Round(KeeperOcrEvery) < 1) ? 1 : Round(KeeperOcrEvery)))
			{
			KbOcrCatches := 0
			gosub, KbWaitUiClear
			KbLr := KbLineCheck(KbLm, KbLt)
			if (KbLr = 1)
				{
				sleep 300
				KbDue := (KbLineCheck(KbLm2, KbLt2) = 1)
				if (KbDue)
					{
					sleep 250
					KbDue := (KbLineCheck(KbLm3, KbLt3) = 1)
					}
				}
			if (KbLr < 0)
				KbOcrLast := "line or bar color not set"
			else
				KbOcrLast := ((KbLr = 1) ? "LOW" : "ok") . " (" . KbLm . " of " . KbLt . " px off)"
			}
		}
	else if (!KeeperAutoBar and !KeeperOcrOn and KbCatches >= Round(KeeperEveryCatches))
		KbDue := true
	if (KbDue)
		{
		gosub, KbGuardClear
		if (KbUiClear and !MgInPlay)
			gosub, KeeperRun
		else
			{
			KbPostponeN := KbPostponeN + 1
			KbOcrCatches := 9999
			KbOcrLast := "recharge postponed - minigame on screen (" . KbPostponeN . "x)"
			}
		}
	}

if (!MacroRunning)
	goto Idle

if (AquariumAuto and !AqBusy and (AqNextTick = 0 or A_TickCount >= AqNextTick))
	gosub, AquariumRun

if (!MacroRunning)
	goto Idle

tooltip, , , , 9

tooltip, Current Task: AutoLookDownCamera, %TooltipX%, %Tooltip7%, 7
; passive mode leaves the mouse alone (only a Stellarwave fight moves it, to click the signs)
if (AutoLookDownCamera == true and !PasIdle())
	{
	send {rbutton up}
	Sleep, % Tm(AutoLookDelay)
	mousemove, LookDownX, LookDownY
	tooltip, Action: Position Mouse, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoLookDelay)
	send {rbutton down}
	tooltip, Action: Hold Right Click, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoLookDelay)
	DllCall("mouse_event", "UInt", 0x01, "UInt", 0, "UInt", 10000)
	tooltip, Action: Move Mouse Down, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoLookDelay)
	send {rbutton up}
	tooltip, Action: Release Right Click, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoLookDelay)
	mousemove, LookDownX, LookDownY
	tooltip, Action: Position Mouse, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoLookDelay)
	}
	
if (!MacroRunning)
	goto Idle

tooltip, Current Task: AutoBlurCamera, %TooltipX%, %Tooltip7%, 7
; the M key would type into whatever window you tabbed to
if (AutoBlurCamera == true and !(PasIdle() and !WinActive("ahk_id " . RobloxHwnd)))
	{
	tooltip, Current Task: AutoBlurCamera, %TooltipX%, %Tooltip7%, 7
	Sleep, % Tm(AutoBlurDelay)
	send {m}
	tooltip, Action: Press M, %TooltipX%, %Tooltip8%, 8
	Sleep, % Tm(AutoBlurDelay)
	}

if (!MacroRunning)
	goto Idle

if (PassiveAll or (SwPassive and SpecialRod = "Stellarwave Melody"))
	goto SwPassiveWatch

if (!CamModeOn and RodSlotKey != "" and !RodEquippedOnce)
	ForceReEquip := true

if (RodSlotKey != "" and (ForceReEquip or (UnstickAfter > 0 and CastFailCount >= UnstickAfter)))
	{
	tooltip, Current Task: Re-equipping Rod (stuck bobber), %TooltipX%, %Tooltip7%, 7
	send {lbutton up}
	send {rbutton up}
	Sleep, % Tm(TA("reeq1", 120))
	if (BagSlotKey != "")
		send {%BagSlotKey%}
	else
		send {%RodSlotKey%}
	Sleep, % Tm(TA("reeq2", 400))
	send {%RodSlotKey%}
	Sleep, % Tm(TA("reeq3", 600))
	CastFailCount := 0
	ForceReEquip := false
	RodEquippedOnce := true
	if (!MacroRunning)
		goto Idle
	}

gosub, TotemMaybeRun
if (!MacroRunning)
	goto Idle
tooltip, Current Task: Casting Rod, %TooltipX%, %Tooltip7%, 7
CastHolding := true
if (CastMode = "Perfect")
	{
	send {lbutton down}
	gosub, PerfectCastRelease
	if (!PCReleased)
		send {lbutton up}
	}
else
	{
	; Smart cast: N casts back to back (hold, release, hold, ...) - the last one is the normal watched cast
	ScN := SmartCastN
	if ScN is not number
		ScN := 1
	ScN := Round(ScN)
	if (ScN > 10)
		ScN := 10
	if (SmartCast and ScN > 1)
		{
		Loop % ScN - 1
			{
			tooltip, Action: Cast %A_Index%/%ScN% (%HoldRodCastDuration%ms), %TooltipX%, %Tooltip8%, 8
			send {lbutton down}
			Sleep, %HoldRodCastDuration%
			send {lbutton up}
			; wait the cast hold time plus 50 ms before the next cast
			Sleep, % HoldRodCastDuration + TA("castgap", 50)
			}
		}
	send {lbutton down}
	tooltip, Action: Casting For %HoldRodCastDuration%ms, %TooltipX%, %Tooltip8%, 8
	CastSeen := false
	if (SmartCast)
		{
		CastT0 := A_TickCount
		while (A_TickCount - CastT0 < HoldRodCastDuration)
			{
			if (!CastSeen)
				CastSeen := CastBarSeen()
			else
				Sleep, 1
			}
		}
	else
		sleep %HoldRodCastDuration%
	send {lbutton up}
	if (SmartCast and !CastSeen)
		{
		CastPostT := A_TickCount
		while (!CastSeen and A_TickCount - CastPostT < TA("castpost", 120))
			CastSeen := CastBarSeen()
		}
	if (SmartCast and CastSeen)
		{
		CastSeenN := CastSeenN + 1
		CastMissN := 0
		}
	else if (SmartCast and CastSeenN >= 3)
		{
		CastMissN := CastMissN + 1
		if (CastMissN <= 2)
			{
			CastHolding := false
			tooltip, Action: Cast did not go through - recasting (%CastMissN%/2), %TooltipX%, %Tooltip8%, 8
			Sleep, % Tm(TA("castretry", 150))
			if (CastMissN = 2 and RodSlotKey != "")
				ForceReEquip := true
			goto RestartMacro
			}
		CastMissN := 0
		CastSeenN := 0
		}
	}
CastHolding := false
if (!MacroRunning)
	goto Idle
tooltip, Action: Waiting For Bobber (%WaitForBobberDelay%ms), %TooltipX%, %Tooltip8%, 8
KbPreT0 := A_TickCount
KbPreWait := Tm(WaitForBobberDelay)
; read the Keeperbound power bar now, while the bobber flies - so the end of the fight never waits on it
if (KeeperAuto and KeeperAutoBar and !KbBusy)
	{
	if (KbPreSkip > 0)
		KbPreSkip := KbPreSkip - 1
	else if (KbOcrCatches >= ((Round(KeeperOcrEvery) < 1) ? 1 : Round(KeeperOcrEvery)))
		gosub, KbPreRead
	}
; the totem check reads its icons now too, while nothing else happens - only if the read fits in the wait
if (TotemAuto and !TotemPreDone and (!TotemLastCheck or A_TickCount - TotemLastCheck >= TotemPollSec * 1000))
	{
	TotemLeft := KbPreWait - (A_TickCount - KbPreT0)
	if (TotemLeft >= ((TotemReadMs = "") ? 400 : TotemReadMs + 60))
		gosub, TotemAssess
	}
KbPreLeft := KbPreWait - (A_TickCount - KbPreT0)
if (KbPreLeft > 0)
	Sleep, %KbPreLeft%
if (!MacroRunning)
	goto Idle

if (ShakeMode == "Disabled")
goto BarMinigame
else
goto NavigationShakeMode

;====================================================================================================;

SwPassiveWatch:
if (WinActive("ahk_id " . RobloxHwnd))
	{
	send {lbutton up}
	send {rbutton up}
	}
tooltip, Current Task: Passive - watching for the minigame, %TooltipX%, %Tooltip7%, 7
tooltip, , , , 8
tooltip, , , , 10
MgInPlay := false
if (SpecialRod = "Stellarwave Melody")
	SwFightReset()
if (SpecialRod = "Tranquility")
	TqResetAll()
PasSeen := 0
Loop
	{
	if (!MacroRunning)
		goto Idle
	PasStellar := (SwPassive and SpecialRod = "Stellarwave Melody")
	if (!PassiveAll and !PasStellar)
		goto RestartMacro
	; tabbed out with something covering the fish bar: those pixels are not Roblox, so do not look at them
	if (!PasRobloxShown())
		{
		PasSeen := 0
		Sleep, 100
		continue
		}
	gosub, CaptureFishBar
	if (SpecialRod = "Tranquility")
		{
		PasSeen := ManiaVisible() ? PasSeen + 1 : 0
		if (PasSeen >= 2)
			{
			tooltip, , , , 7
			gosub, PasFocus
			goto BarMinigame
			}
		if (PasSeen)
			{
			Sleep, 5
			continue
			}
		}
	else
		{
		if (FishLineVisible() or BarPresent())
			{
			tooltip, , , , 7
			gosub, PasFocus
			goto BarMinigame
			}
		if ((SpecialRod = "Stellarwave Melody") ? ((SwPreset = "Ominous Ouija") ? OjSeen() : (SwFrameTop() >= 0)) : MinigameVisible(6))
			{
			SwBurstT0 := A_TickCount
			while (MacroRunning and A_TickCount - SwBurstT0 < 1500)
				{
				gosub, CaptureFishBar
				if (FishLineVisible() or BarPresent())
					{
					tooltip, , , , 7
					gosub, PasFocus
					goto BarMinigame
					}
				Sleep, 5
				}
			}
		}
	SwPassWait := PasStellar ? SwPassiveMs : PassiveMs
	if SwPassWait is not number
		SwPassWait := 500
	Sleep, % (SwPassWait < 10) ? 10 : Round(SwPassWait)
	}

; a minigame showed up while you were in another window - Roblox has to be in front to play it
PasFocus:
if (RobloxHwnd and !WinActive("ahk_id " . RobloxHwnd))
	{
	WinActivate, ahk_id %RobloxHwnd%
	WinWaitActive, ahk_id %RobloxHwnd%, , 1
	}
return

NavigationShakeFailsafe:
NavigationFailsafeCount++
tooltip, Failsafe: %NavigationFailsafeCount%/%NavigationShakeFailsafe%, %TooltipX%, %Tooltip10%, 10
if (NavigationFailsafeCount >= NavigationShakeFailsafe)
	{
	settimer, NavigationShakeFailsafe, off
	CastFailCount++
	ForceReset := true
	}
return

NavigationShakeMode:

tooltip, Current Task: Shaking, %TooltipX%, %Tooltip7%, 7
tooltip, Attempt Count: 0, %TooltipX%, %Tooltip8%, 8

tooltip, Failsafe: 0/%NavigationShakeFailsafe%, %TooltipX%, %Tooltip10%, 10

MgInPlay := false
if (SpecialRod = "Tranquility")
	TqResetAll()
if (SpecialRod = "Stellarwave Melody")
	SwFightReset()
NavigationFailsafeCount := 0
NavigationCounter := 0
ForceReset := false
MinigameSeen := 0
MgScore := 0
MgConf := 0
settimer, NavigationShakeFailsafe, 1000
NavigationShakeModeRedo:
if (!MacroRunning)
	goto Idle
if (ForceReset == true)
	{
	tooltip, , , , 10
	goto RestartMacro
	}
Sleep, % Tm(NavigationSpamDelay)
if (SpecialRod = "Splitbranch Twig")
	gosub, TwigMaybePick
gosub, CaptureFishBar
if (SpecialRod = "Tranquility")
	{
	MinigameSeen := ManiaVisible() ? MinigameSeen + 1 : 0
	MinigameHit := (MinigameSeen >= 2)
	}
else
	{
	MinigameHit := FishLineVisible()
	if (MinigameHit)
		MinigameSeen := 0
	else
		{
		MinigameSeen := MinigameVisible(6) ? MinigameSeen + 1 : 0
		if (MinigameSeen >= ((SpecialRod = "Stellarwave Melody") ? 1 : 2))
			MinigameHit := true
		}
	}
if (MinigameHit and (SpecialRod = "Tranquility" or SpecialRod = "Lullaby" or SpecialRod = "Stellarwave Melody" or UiStartGate()))
	{
	settimer, NavigationShakeFailsafe, off
	goto BarMinigame
	}
else
	{
	if (!MinigameHit)
		UiPhantomT := 0
	NavigationCounter++
	tooltip, Attempt Count: %NavigationCounter%, %TooltipX%, %Tooltip8%, 8
	sleep 1
	send {enter}
	goto NavigationShakeModeRedo
	}

;====================================================================================================;

CastChargeCheck:
if (MgCastCharged or WindowHeight < 100)
	return
PCSearchTop := Round(WindowHeight * 0.13)
PCSearchBottom := Round(WindowHeight * 0.90)
PCVerifyOff := false
Loop, 2
	{
	if (A_Index = 2)
		Sleep, % Tm(TA("chg", 40))
	PCLastGoodY := -1
	PCGreenY := -1
	if (!PerfectAcquireGreen() or PerfectTrackFrame() != 2)
		return
	}
MgCastCharged := true
return

TwigMaybePick:
if (!MacroRunning)
	return
DllCall("QueryPerformanceCounter", "Int64*", TwigNow)
if (TwigLastCheck and ((TwigNow - TwigLastCheck) / QpcFreq) < 0.30)
	return
TwigLastCheck := TwigNow
if (!TwigPrompt(TwigLX, TwigRX, TwigLabY))
	return
tooltip, Action: Splitbranch Twig - choosing a fish, %TooltipX%, %Tooltip8%, 8
MouseGetPos, TwigSaveX, TwigSaveY
TwigIconY := Round(WindowHeight * 0.493)
for TwigI, TwigT in [[TwigLX, TwigIconY], [TwigRX, TwigIconY], [TwigLX, TwigLabY], [TwigRX, TwigLabY]]
	{
	if (!MacroRunning)
		break
	TwigCX := TwigT[1]
	TwigCY := TwigT[2]
	MouseMove, %TwigCX%, %TwigCY%, 0
	Sleep, % Tm(TA("twig1", 40))
	send {lbutton down}
	Sleep, % Tm(TA("twig2", 40))
	send {lbutton up}
	Sleep, % Tm(TA("twig3", 260))
	if (!TwigPrompt(TwigLX, TwigRX, TwigLabY))
		break
	}
MouseMove, %TwigSaveX%, %TwigSaveY%, 0
DllCall("QueryPerformanceCounter", "Int64*", TwigLastCheck)
return

BarCalculationFailsafe:
BarCalcFailsafeCounter++
BarCalcLimit := BarCalculationFailsafe
tooltip, Failsafe: %BarCalcFailsafeCounter%/%BarCalcLimit%, %TooltipX%, %Tooltip10%, 10
if (BarCalcFailsafeCounter >= BarCalcLimit)
	{
	settimer, BarCalculationFailsafe, off
	CastFailCount++
	ForceReEquip := true
	ForceReset := true
	}
return

BarMinigame:
MgInPlay := true
DbX0 := -1
DbSeenQ := 0
DbMoveQ := 0
DbInv := false
if (SpecialRod = "Stellarwave Melody" and ShakeMode == "Disabled")
	SwFightReset()
UiEdgeReset()
BarColRing := []
BarColT := 0
RemBarRing := []
HudWRing := []
HudWMed := 0

CastFailCount := 0
if (SpecialRod = "Tranquility")
	{
	tooltip, Current Task: Playing Notes, %TooltipX%, %Tooltip7%, 7
	tooltip, , , , 8
	tooltip, , , , 10
	ForceReset := false
	MinigameLost := 0
	DllCall("QueryPerformanceCounter", "Int64*", TqNowC)
	TqResetFight(TqNowC / QpcFreq)
	goto BarMinigame2
	}

tooltip, Current Task: Calculating Bar Size, %TooltipX%, %Tooltip7%, 7
tooltip, Bar Size: Not Found, %TooltipX%, %Tooltip8%, 8
tooltip, Failsafe: 0/%BarCalculationFailsafe%, %TooltipX%, %Tooltip10%, 10

ForceReset := false
BarCalcFailsafeCounter := 0
MgFightMode := false
MgOverWhy := ""
PasNow := (PassiveAll or (SwPassive and SpecialRod = "Stellarwave Melody"))
PasLastSeen := A_TickCount
if (!PasNow)
	settimer, BarCalculationFailsafe, 1000
else
	tooltip, Failsafe: off (passive), %TooltipX%, %Tooltip10%, 10

if (SpecialRod = "Noiseform")
	{
	NoiseWCal := 0
	NoiseWCnt := {}
	NoiseWVote := 0
	NoisePrevC := -1
	NoisePrevT := 0
	NoiseVelC := 0
	NoiseCoastN := 0
	NoiseStillX := -1
	NoiseStillC := 0
	NoiseLostN := 0
	NoiseEHist := []
	NoiseBandT := -99
	NoiseBandB := -99
	NoiseRlW := 0
	NoiseRlN := 0
	NoiseFishPrev := -1
	NoiseFishT := 0
	NoiseFoundStreak := 0
	NoiseJumpHold := 0
	NoiseStuckN := 0
	NoiseStuckRel := 0
	NoiseStaleN := 0
	NoiseStaleBlk := 0
	NoiseOnZoneN := 0
	NoiseLastBarX := -1
	NoiseAltW := 0
	NoiseAltN := 0
	NoiseZSeenT := 0
	NoiseRate := 1
	NoiseRateT := 0
	NoiseN6 := 6
	NoiseN8 := 8
	NoiseN15 := 15
	NoiseN45 := 45
	HudZoneShown := false
	HudDirty := true
	}

BarMinigameRedo:
if (!MacroRunning)
	goto Idle
if (SpecialRod = "Splitbranch Twig")
	gosub, TwigMaybePick
if (ForceReset == true)
	{
	tooltip, , , , 10
	goto RestartMacro
	}
gosub, CaptureFishBar
if (PasNow)
	{
	if (BarPresent() or FishLineVisible() or MinigameVisible(6) or (SpecialRod = "Stellarwave Melody" and ((SwPreset = "Ominous Ouija") ? OjSeen() : (SwFrameTop() >= 0))))
		PasLastSeen := A_TickCount
	else if (A_TickCount - PasLastSeen > TA("passivelost", 3000))
		{
		tooltip, , , , 10
		goto RestartMacro
		}
	}
if (BarPresent() and (SpecialRod = "Stellarwave Melody" or UiStartGate()))
	{
	if (SpecialRod = "Dreambreaker" and !DbSeenQ)
		DllCall("QueryPerformanceCounter", "Int64*", DbSeenQ)
	BarWidthSamples := []
	BarWidthSamples.Push(RunWidth)
	NoiseEntryFish := NoiseFishFresh ? 1 : 0
	Loop, % (SpecialRod = "Stellarwave Melody") ? 3 : 8
		{
		if (!MacroRunning)
			goto Idle
		Sleep, % Tm(TA("barsamp", 12))
		gosub, CaptureFishBar
		if (BarPresent())
			BarWidthSamples.Push(RunWidth)
		if (NoiseFishFresh)
			NoiseEntryFish := NoiseEntryFish + 1
		}
	if (BarWidthSamples.MaxIndex() >= 3 and (SpecialRod != "Noiseform" or NoiseEntryFish >= 2))
		{
		WhiteBarSize := MedianOf(BarWidthSamples)
		BarWCal := WhiteBarSize
		BarWTrust := WhiteBarSize
		goto BarMinigameSingle
		}
	}
sleep 1
goto BarMinigameRedo

;====================================================================================================;

BarMinigameSingle:

UiHoShown := false
UiNoBarN := 0
MgFightMode := true
BarCalcFailsafeCounter := 0
MgCastCharged := false
UiEdgeStart()
tooltip, Current Task: Playing Bar Minigame, %TooltipX%, %Tooltip7%, 7
tooltip, Bar Size: %WhiteBarSize%, %TooltipX%, %Tooltip8%, 8


HalfBarSize := WhiteBarSize/2
MgLastSig := -1
MgStaticN := 0
BarSizeBadN := 0
BarSizePend := 0
BarSizePendN := 0
DllCall("QueryPerformanceCounter", "Int64*", MgStaticAt)
SideDelay := 0
AnkleBreakDelay := 0
DirectionalToggle := "Disabled"
AtLeastFindWhiteBar := false
LastFishX := -1
LastBarL := -1
LastBarR := -1
MinigameLost := 0
BelNoStrong := 0
BelPrevT := [0,0]
BelVel := [0,0]
BelBVel := [0,0]
BelSide := [0,0]
BelAcc := [0,0]
BelBias := [0,0]
HudFish2Tgt := -1
HudFish2Cur := -1
HudBar2Tgt := -1
HudBar2Cur := -1
HudBar2W := 0
NoisePrevC := -1
NoisePrevT := 0
NoiseFishPrev := -1
NoiseFishT := 0
NoiseStillX := -1
NoiseStillC := 0
NoiseWCal := 0
NoiseJumpN := 0
NoiseJumpHold := 0
NoiseStuckN := 0
NoiseStuckRel := 0
NoiseStaleN := 0
NoiseStaleBlk := 0
NoiseOnZoneN := 0
NoiseLastBarX := -1
NoiseRate := 1
NoiseRateT := 0
NoiseN6 := 6
NoiseN8 := 8
NoiseN15 := 15
NoiseN45 := 45
NoiseAltW := 0
NoiseAltN := 0
NoiseZSeenT := 0
NoiseWCnt := {}
NoiseWVote := 0
NoiseLastD := 0
NoiseOscN := 0
NoiseVelC := 0
NoiseLostN := 0
NoiseRowOff := 0
NoiseCoastN := 0
NoiseWBase := 0
NoiseWBaseML := 0
NoiseWDthr := 6
NoiseZoneTgt := -1
NoiseZoneT := 0
NoiseZoneKind := ""
NoiseZScanT := 0
NoiseZFreshT := 0
NoisePendKind := ""
NoisePendT := 0
NoiseWNow := ""
NoiseWBlk := 0
NoiseDkRing := []
NoiseMlRing := []
NoiseD6Ring := []
NoiseDkIdx := 0
NoiseDkN := 0
NoiseWGT := 0
DkI := 0
while (DkI < 32)
	{
	NoiseDkRing[DkI] := -1
	NoiseMlRing[DkI] := -1
	NoiseD6Ring[DkI] := -1
	DkI := DkI + 1
	}
NoiseMissN := 0
NoiseMissT := 0
WMissN := 0
WMissT := 0
WRW := 0
WRH := 0
WRN := 0
WRIdx := 0
WRSkip := 0
NoiseZWx := -1
NoiseZGx := -1
NoiseZKx := -1
NoiseZOK := false
NfPW := -1
NfPG := -1
NfPK := -1
NfCW := -1
NfCG := -1
NfCK := -1
NfIconN := 0
NfGoneN := 0
NfLatchKind := ""
NfLatchT := 0
NfRingN := 0
NfRingIdx := 0
NfWhy := ""
NoiseEHist := []
NoiseBandT := -99
NoiseBandB := -99
NoiseRlW := 0
NoiseRlN := 0
RelLock := 0
DutyAvg := 0.5
DarkAcc := 0
NoteAcc := 0
DarkHoldN := 0
DarkFlashing := false
NoteLockX := -1
NoteLockN := 0
NoteNextX := -1
NoteNextY := -1
NoteLockY := -1
NoteHoldX := -1
PnState := 0
PnFall := 0
PnFallN := 0
PnRes := 0
PnGlueAt := 0
PnGlueLo := 0
PnGlueHi := 0
PnAwayAt := 0
PnTwoN := 0
PnResBlockUntil := 0
PnPrevT := 0
PnPrevY := -1
PnPrevX := -1
PnProg := -1
PnNoteX := -1
PnCoverX := -1
PnImpactAt := 0
PnWhy := ""
PnSeenY := -1
PnSeenAt := 0
PnLandAt := 0
PnLeaveAt := 0
PnGone := false
PnTipAt := 0
LullFrames := 0
LullCalN := 0
LullR := 0
LullSecN := 0
LullCalLt := []
LullCalDk := []
LullCalLs := []
LullBg := []
LullSecA := []
LullSecB := []
LullArmA := []
LullClrT := []
LullActive := false
LullSeen := false
LullGoneN := 0
LullClicks := 0
NoteAllN := 0
LineBarW := -1
LineBarAge := 99

MaxLeftToggle := false
MaxRightToggle := false

PrevBarX := -1
PrevFishX := -1
PrevSampleT := 0
BarVel := 0.0
FishVel := 0.0
PrevPosAbs := -1
PrecisionDown := false
PrecisionResendAt := 0
BarLostAt := 0
NoFishAt := 0
BlindAcc := 0
BarWOutFirst := 0
BarWCal := WhiteBarSize
BarWRing := []
BarWMed := 0
BarWOutN := 0
HudWRing := []
HudWMed := 0
BarWidthTrusted := true
BarLiveL := -1
BarLiveR := -1
BarLiveMiss := 0
BarWLive := -1
BarLiveOnlyAt := 0
CastBlindN := 0
CastPrevL := -1
CastPrevW := -1
CastPrevF := -1
CastSameN := 0
CastSameT := 0
CastStatic := false
RemWhiteX := -1
RemBlackX := -1
RemTargetX := -1
CtrAcc := 0
CtrBias := 0
MiguLastX := -1
NoiseFoundStreak := 0
ZoneInset := WhiteBarSize*SideBarRatio
ZoneInsetMax := (TrackRight-TrackLeft)*0.4
if (ZoneInset > ZoneInsetMax)
	ZoneInset := ZoneInsetMax
MaxLeftBar := TrackLeft+ZoneInset
MaxRightBar := TrackRight-ZoneInset

gosub, ShowHud
gosub, UpdateHud

BarMinigame2:
if (!MacroRunning)
	goto Idle
if (ForceReset == true)
	{
	MgOverWhy := "forcereset"
	goto BarMinigameOver
	}
DllCall("QueryPerformanceCounter", "Int64*", PfA)
PfDt := PfPrev ? Round((PfA - PfPrev) * 1000.0 / QpcFreq, 1) : 0
PfPrev := PfA
sleep 0
if (SwPressK)
	SwPressTick()
DllCall("QueryPerformanceCounter", "Int64*", PfB)
gosub, CaptureFishBar
DllCall("QueryPerformanceCounter", "Int64*", PfC)
PfSleep := Round((PfB - PfA) * 1000.0 / QpcFreq, 1)
PfCap := Round((PfC - PfB) * 1000.0 / QpcFreq, 1)
UiGoneNow := (SpecialRod != "Tranquility" and SpecialRod != "Lullaby" and SpecialRod != "Stellarwave Melody" and UiEdgeTick() = "gone")
if (UiGoneNow)
	{
	MgOverWhy := "uigone"
	goto BarMinigameOver
	}
if (UiGoneT and SpecialRod != "Tranquility" and SpecialRod != "Lullaby" and SpecialRod != "Stellarwave Melody")
	{
	DllCall("QueryPerformanceCounter", "Int64*", UiFastNow)
	if (!BarPresent() and !FishLineVisible())
		UiNoBarN := UiNoBarN + 1
	else
		UiNoBarN := 0
	if (UiNoBarN >= 2 and ((UiFastNow - UiGoneT) * 1000.0 / QpcFreq) >= TA("uigonefast", 0))
		{
		UiNoBarN := 0
		MgOverWhy := "uigone"
		goto BarMinigameOver
		}
	}
else
	UiNoBarN := 0
if (SpecialRod = "Lullaby")
	{
	if (LullScan())
		{
		send {lbutton down}
		Sleep, % Tm(TA("lullhold", 20))
		send {lbutton up}
		LullClicks := LullClicks + 1
		tooltip, Lullaby: %LullSecN% light sector(s)`, hits %LullClicks% (last #%LullHitSec%), %TooltipX%, %Tooltip9%, 9
		}
	if (LullActive)
		{
		LullSeen := true
		LullGoneN := 0
		}
	else if (LullSeen)
		{
		LullGoneN := LullGoneN + 1
		if (LullGoneN >= 25)
			{
			MgOverWhy := "lullaby-done"
			goto BarMinigameOver
			}
		}
	goto BarMinigame2
	}

if (SpecialRod = "Tranquility")
	{
	DllCall("QueryPerformanceCounter", "Int64*", TqNowC)
	if (!ManiaStep(TqNowC / QpcFreq))
		{
		if (TqExpired)
			{
			CastFailCount++
			ForceReEquip := true
			tooltip, , , , 10
			goto RestartMacro
			}
		goto BarMinigameOver
		}
	goto BarMinigame2
	}

if (SpecialRod = "Bellona's Waraxe")
	{
	BelRes := BellonaScan()
	if (BelRes = 2)
		BelNoStrong := 0
	else
		BelNoStrong++
	if (BelRes = 0)
		{
		MinigameLost++
		if (MinigameLost = 1)
			BellonaRelease()
		if (MinigameLost >= 8)
			goto BarMinigameOver
		goto BarMinigame2
		}
	MinigameLost := 0
	if (BelNoStrong >= 150)
		{
		BellonaRelease()
		goto BarMinigameOver
		}
	BellonaDrive(1)
	BellonaDrive(2)
	if (BelOK[1])
		{
		if (BelF[1] >= 0)
			MoveHudFish(FishBarLeft + BelF[1])
		MoveHudBarSpan(FishBarLeft + BelA[1], BelB[1] - BelA[1])
		}
	if (BelOK[2])
		{
		if (BelF[2] >= 0)
			MoveHudFish2(FishBarLeft + BelF[2])
		MoveHudBar2Span(FishBarLeft + BelA[2], BelB[2] - BelA[2])
		}
	if (HudNoteX >= 0)
		MoveHudNote(-1)
	if (HudNote2X >= 0)
		MoveHudNote2(-1)
	if (HudZoneShown)
		{
		HudZoneShown := false
		HudDirty := true
		}
	goto BarMinigame2
	}

FoundBar := BarPresent()
if (FoundBar and (SpecialRod = "None" or SpecialRod = "Splitbranch Twig") and BarWCal > 0 and RunWidth < BarWCal * 0.2)
	{
	FoundBar := false
	}
LineSeen := FishLineVisible()
if (!FoundBar and !LineSeen and SpecialRod != "Remembrance" and SpecialRod != "MiguRod" and SpecialRod != "Halibut Harpoon"
	and SpecialRod != "Tryhard Rod" and SpecialRod != "Stellarwave Melody")
	LineSeen := (FindArrowX() >= 0)
if (!FoundBar and !LineSeen)
	{
	NoiseFoundStreak := 0
	MinigameLost++
	if (MinigameLost = 1)
		{
		if (UiState != 2 and !SwPressK)
			gosub, CastChargeCheck
		if (!SwPressK)
			send {lbutton up}
		SwWantK := 0
		PrecisionDown := false
		DllCall("QueryPerformanceCounter", "Int64*", BarLostAt)
		HudLossHidden := false
		}
	DllCall("QueryPerformanceCounter", "Int64*", BarLostNow)
	if (!HudLossHidden and BarLostAt and ((BarLostNow - BarLostAt) * 1000.0 / QpcFreq) > TA("barhide", 150))
		{
		gosub, HideHud
		HudLossHidden := true
		}
	BarLostMs := BarLostAt ? (BarLostNow - BarLostAt) * 1000.0 / QpcFreq : 0
	BarLostLimNow := BarLostLim()
	if (SpecialRod = "Stellarwave Melody" and SwPreset = "Ominous Ouija")
		{
		; the tokens can cover the bar (and its look may not be picked up): keep clicking letters, and the fight
		; is not over while its stars still show - it ends the moment they are gone
		OjStep()
		if (OjStarsVis)
			BarLostLimNow := 2147483647
		else if (OjStarSeenT and BarLostMs >= TA("swendfast", 120) and A_TickCount - OjStarSeenT >= 80)
			{
			MgOverWhy := "ojend"
			goto BarMinigameOver
			}
		}
	else if (SpecialRod = "Stellarwave Melody" and SwStarOkT)
		{
		; the star row goes away together with the bar when the fight is over - then it is over at once.
		; While the stars still show, the bar is only hidden behind the signs: never end it early then
		if (!SwStarsValid)
			{
			if (!SwStarGoneAt)
				SwStarGoneAt := BarLostNow
			if (BarLostMs >= TA("swendfast", 120) and (BarLostNow - SwStarGoneAt) * 1000.0 / QpcFreq >= 80)
				{
				MgOverWhy := "swend"
				goto BarMinigameOver
				}
			}
		else
			{
			SwStarGoneAt := 0
			if (BarLostLimNow < TA("barlost", 450))
				BarLostLimNow := TA("barlost", 450)
			}
		}
	else if (UiState = 2 and !UiGoneT and BarLostLimNow < TA("barlost", 450))
		BarLostLimNow := TA("barlost", 450)
	if (BarLostAt and BarLostMs > BarLostLimNow)
		{
		MgOverWhy := "barlost"
		goto BarMinigameOver
		}
	goto BarMinigame2
	}
if (MinigameLost and HudBuilt and HudLossHidden)
	gosub, ShowHud
HudLossHidden := false
MinigameLost := 0
BarLostAt := 0
SwStarGoneAt := 0
NoiseFoundStreak := NoiseFoundStreak + 1

if (FoundBar and RunWidth > 0)
	{
	if (BarWidthTrusted and !(BarWCal > 0 and RunWidth > BarWCal * 1.3))
		{
		if (BarWMed <= 0 or Abs(RunWidth - BarWMed) <= (BarWMed * 0.25))
			{
			BarWPush(RunWidth)
			BarWOutN := 0
			BarWOutFirst := 0
			}
		else
			{
			if (BarWOutN > 0 and BarWOutFirst > 0 and Abs(RunWidth - BarWOutFirst) <= (BarWOutFirst * 0.15))
				BarWOutN := BarWOutN + 1
			else
				{
				BarWOutFirst := RunWidth
				BarWOutN := 1
				}
			if (BarWOutN >= 4)
				{
				BarWRing := []
				BarWMed := 0
				BarWOutN := 0
				BarWOutFirst := 0
				BarWPush(RunWidth)
				}
			}
		}
	NewBarSize := (BarWMed > 0) ? BarWMed : RunWidth
	if (SpecialRod = "Noiseform" and NoiseWCal >= 40)
		NewBarSize := NoiseWCal
	if (!HudZoneShown and HudBuilt and (SpecialRod != "Noiseform" or NoiseWCal >= 40))
		{
		HudZoneShown := true
		HudDirty := true
		}
	BarWTrust := (BarWMed > 0 and Abs(RunWidth - BarWMed) <= (BarWMed * 0.25)) ? RunWidth : NewBarSize
	if (BarWidthTrusted and Abs(NewBarSize - WhiteBarSize) > (WhiteBarSize * 0.2))
		{
		WhiteBarSize := NewBarSize
		HalfBarSize := WhiteBarSize/2
		ZoneInset := WhiteBarSize*SideBarRatio
		ZoneInsetMax := (TrackRight-TrackLeft)*0.4
		if (ZoneInset > ZoneInsetMax)
			ZoneInset := ZoneInsetMax
		MaxLeftBar := TrackLeft+ZoneInset
		MaxRightBar := TrackRight-ZoneInset
		gosub, UpdateHud
		}
	}

DllCall("QueryPerformanceCounter", "Int64*", PfD)
FishX := GetFishPos()
DllCall("QueryPerformanceCounter", "Int64*", PfE)
if (SpecialRod = "Stellarwave Melody")
	{
	if (SwPreset = "Ominous Ouija")
		OjStep()
	else
		SwClickStep()
	}

if (SpecialRod != "Tranquility" and SpecialRod != "Lullaby" and SpecialRod != "Noiseform")
	{
	if (FishX >= 0)
		NoFishAt := 0
	else if (!NoFishAt)
		NoFishAt := A_TickCount
	else if ((A_TickCount - NoFishAt) > TA("nofish", 8000))
		{
		MgOverWhy := "nofishline"
		goto BarMinigameOver
		}
	}

NoteAt := NoteTarget()
TargetIsNote := false
DllCall("QueryPerformanceCounter", "Int64*", PfF)
PfFish := Round((PfE - PfD) * 1000.0 / QpcFreq, 1)
PfNote := Round((PfF - PfE) * 1000.0 / QpcFreq, 1)
MoveHudNote(DarkFlashing ? FishX : ((SpecialRod = "Pinions Aria" and NoteAt < 0 and NoteBias >= 100) ? NoteHoldX : NoteAt))
if (SpecialRod = "Remembrance")
	MoveHudNote(RemBlackX)
MoveHudNote2((SpecialRod = "Pinions Aria" and !DarkFlashing) ? NoteNextX : -1)
if (FishX >= 0)
	MoveHudFish(FishX)
if (SpecialRod = "Pinions Aria")
	{
	FishX := PinionPlan(FishX, NoteAt, TargetIsNote)
	DllCall("QueryPerformanceCounter", "Int64*", PnTipNow)
	if (!PnTipAt or ((PnTipNow - PnTipAt) / QpcFreq) >= 0.2)
		{
		PnTipAt := PnTipNow
		PnTipTxt := "Pinions: progress "
		if (PnProg >= 0)
			PnTipTxt .= Round(PnProg * 100) . "%"
		else
			PnTipTxt .= "?"
		PnTipTxt .= "  |  " . PnWhy
		tooltip, %PnTipTxt%, %TooltipX%, %Tooltip13%, 13
		}
	}
else if (NoteAt >= 0)
	{
	NoteW2 := NoteBias
	if (SpecialRod = "Noiseform" or SpecialRod = "Halibut Harpoon")
		NoteW2 := 100
	if (NoteW2 < 0)
		NoteW2 := 0
	if (NoteW2 > 100)
		NoteW2 := 100
	if (SpecialRod = "Halibut Harpoon" and FishX >= 0 and RunWidth > 0)
		NoteAt := Min(Max(NoteAt, FishX - RunWidth * 0.42), FishX + RunWidth * 0.42)
	if (FishX >= 0)
		FishX := ((NoteAt * NoteW2) + (FishX * (100 - NoteW2))) / 100
	else if (SpecialRod != "Noiseform" and SpecialRod != "Halibut Harpoon")
		FishX := NoteAt
	if (SpecialRod = "Pinions Aria")
		{
		NoteHoldX := NoteAt
		DllCall("QueryPerformanceCounter", "Int64*", NoteHoldAt)
		}
	TargetIsNote := (NoteW2 >= 60)
	}
else if (SpecialRod = "Pinions Aria" and NoteBias >= 100 and NoteHoldX >= 0)
	{
	DllCall("QueryPerformanceCounter", "Int64*", NoteHoldNow)
	if (NoteHoldAt and ((NoteHoldNow - NoteHoldAt) * 1000.0 / QpcFreq) < 220)
		{
		FishX := NoteHoldX
		TargetIsNote := true
		}
	else
		NoteHoldX := -1
	}
if (DarkFlashing)
	{
	DarkAcc := DarkAcc + DutyAvg
	if (DarkAcc >= 1)
		{
		DarkAcc := DarkAcc - 1
		gosub, PrecisionHold
		}
	else
		gosub, PrecisionRelease
	goto BarMinigame2
	}
if (FishX >= 0 and RunWidth > 0)
	{
	DutyErr := Abs(FishX - (RunLeft + RunWidth / 2))
	DutyNear := TargetIsNote ? NoteHoldZone(RunWidth) : 30
	if (DutyNear < 30)
		DutyNear := 30
	if (DutyErr < DutyNear)
		DutyAvg := DutyAvg * 0.9 + (PrecisionDown ? 0.1 : 0)
	}
if (FishX < 0 and SpecialRod = "Noiseform")
	{
	NoiseLostN := NoiseLostN + 1
	if (NoiseLostN = 1)
		NoiseLostAt := A_TickCount

	gosub, PrecisionRelease
	if (NoiseLostN >= 60 and (A_TickCount - NoiseLostAt) >= TA("noiselost", 2000))
		{
		MgOverWhy := "nofish60"
		goto BarMinigameOver
		}
	goto BarMinigame2
	}
if (SpecialRod = "Noiseform")
	NoiseLostN := 0
if (FishX >= 0)
	{
	if (ControlMode = "Precision" or ControlMode = "Lines" or SpecialRod = "Requiem")
		goto BarPrecisionControl
	if (FishX < MaxLeftBar)
		{
		if (MaxLeftToggle == false)
			{
			MoveHudBarSpan(RunLeft, RunWidth)
			DirectionalToggle := "Right"
			MaxLeftToggle := true
			send {lbutton up}
			sleep 1
			send {lbutton up}
			sleep %SideDelay%
			AnkleBreakDelay := 0
			SideDelay := 0
			}
		goto BarMinigame2
		}
	else if (FishX > MaxRightBar)
		{
		if (MaxRightToggle == false)
			{
			MoveHudBarSpan(RunLeft, RunWidth)
			DirectionalToggle := "Left"
			MaxRightToggle := true
			send {lbutton down}
			sleep 1
			send {lbutton down}
			sleep %SideDelay%
			AnkleBreakDelay := 0
			SideDelay := 0
			}
		goto BarMinigame2
		}
	MaxLeftToggle := false
	MaxRightToggle := false
	if (FoundBar)
		{
		AtLeastFindWhiteBar := true
		BarX := RunLeft+(RunWidth/2)
		if (BarX > FishX)
			{
			MoveHudBarSpan(RunLeft, RunWidth)
			Difference := (BarX-FishX)*ResolutionScaling*StableLeftMultiplier
			CounterDifference := Difference/StableLeftDivision
			send {lbutton up}
			if (DirectionalToggle == "Right")
				{
				sleep %AnkleBreakDelay%
				AnkleBreakDelay := 0
				}
			else
				{
				AnkleBreakDelay := AnkleBreakDelay+(Difference-CounterDifference)*LeftAnkleBreakMultiplier
				SideDelay := AnkleBreakDelay/LeftAnkleBreakMultiplier*SideBarWaitMultiplier
				}
			SleepTrack(Difference, "Left", false)
			CounterDifference := CounterDifference*HeldFraction
			gosub, CaptureFishBar
			FishX := GetFishPos()
			if (UiHandsOff(true))
				goto BarMinigame2
			if (FishX < MaxLeftBar)
				goto BarMinigame2
			send {lbutton down}
			sleep %CounterDifference%
			gosub, StabilizeBurst
			DirectionalToggle := "Left"
			}
		else
			{
			MoveHudBarSpan(RunLeft, RunWidth)
			Difference := (FishX-BarX)*ResolutionScaling*StableRightMultiplier
			CounterDifference := Difference/StableRightDivision
			send {lbutton down}
			if (DirectionalToggle == "Left")
				{
				sleep %AnkleBreakDelay%
				AnkleBreakDelay := 0
				}
			else
				{
				AnkleBreakDelay := AnkleBreakDelay+(Difference-CounterDifference)*RightAnkleBreakMultiplier
				SideDelay := AnkleBreakDelay/RightAnkleBreakMultiplier*SideBarWaitMultiplier
				}
			SleepTrack(Difference, "Right", false)
			CounterDifference := CounterDifference*HeldFraction
			gosub, CaptureFishBar
			FishX := GetFishPos()
			if (UiHandsOff(true))
				goto BarMinigame2
			if (FishX > MaxRightBar)
				goto BarMinigame2
			send {lbutton up}
			sleep %CounterDifference%
			gosub, StabilizeBurst
			DirectionalToggle := "Right"
			}
		}
	else
		{
		tooltip, Bar NOT FOUND, %TooltipX%, %Tooltip9%, 9
		if (AtLeastFindWhiteBar == false)
			{
			if (FishLineVisible() or FindArrowX() >= 0)
				{
				send {lbutton down}
				send {lbutton up}
				}
			goto BarMinigame2
			}

		ArrowX := FindArrowX()
		if (ArrowX < 0)
			ArrowX := FindColorX(0x878584, ArrowColorTolerance)
		if (ArrowX < 0)
			goto BarMinigame2
		if (ArrowX > FishX)
			{
			MoveHudBarC(ArrowX)
			Difference := HalfBarSize*UnstableLeftMultiplier
			CounterDifference := Difference/UnstableLeftDivision
			send {lbutton up}
			if (DirectionalToggle == "Right")
				{
				sleep %AnkleBreakDelay%
				AnkleBreakDelay := 0
				}
			else
				{
				AnkleBreakDelay := AnkleBreakDelay+(Difference-CounterDifference)*LeftAnkleBreakMultiplier
				SideDelay := AnkleBreakDelay/LeftAnkleBreakMultiplier*SideBarWaitMultiplier
				}
			SleepTrack(Difference, "Left", true)
			CounterDifference := CounterDifference*HeldFraction
			gosub, CaptureFishBar
			FishX := GetFishPos()
			if (UiHandsOff(true))
				goto BarMinigame2
			if (FishX < MaxLeftBar)
				goto BarMinigame2
			send {lbutton down}
			sleep %CounterDifference%
			gosub, StabilizeBurst
			DirectionalToggle := "Left"
			}
		else
			{
			MoveHudBarC(ArrowX)
			Difference := HalfBarSize*UnstableRightMultiplier
			CounterDifference := Difference/UnstableRightDivision
			send {lbutton down}
			if (DirectionalToggle == "Left")
				{
				sleep %AnkleBreakDelay%
				AnkleBreakDelay := 0
				}
			else
				{
				AnkleBreakDelay := AnkleBreakDelay+(Difference-CounterDifference)*RightAnkleBreakMultiplier
				SideDelay := AnkleBreakDelay/RightAnkleBreakMultiplier*SideBarWaitMultiplier
				}
			SleepTrack(Difference, "Right", true)
			CounterDifference := CounterDifference*HeldFraction
			gosub, CaptureFishBar
			FishX := GetFishPos()
			if (UiHandsOff(true))
				goto BarMinigame2
			if (FishX > MaxRightBar)
				goto BarMinigame2
			send {lbutton up}
			sleep %CounterDifference%
			gosub, StabilizeBurst
			DirectionalToggle := "Right"
			}
		}
	goto BarMinigame2
	}

BlindAcc := BlindAcc + DutyAvg
if (BlindAcc >= 1)
	{
	BlindAcc := BlindAcc - 1
	gosub, PrecisionHold
	}
else
	gosub, PrecisionRelease
goto BarMinigame2

BarPrecisionControl:

if (!FoundBar)
	{
	if (SpecialRod = "Castbound" and CastBlindN < 40)
		{
		CastBlindN := CastBlindN + 1
		NoteAcc := NoteAcc + DutyAvg
		if (NoteAcc >= 1)
			{
			NoteAcc := NoteAcc - 1
			WantDown := true
			}
		else
			WantDown := false
		goto PrecisionApply
		}
	if (SpecialRod = "Remembrance" or SpecialRod = "MiguRod" or SpecialRod = "Halibut Harpoon" or SpecialRod = "Tryhard Rod" or SpecialRod = "Stellarwave Melody")
		{
		gosub, PrecisionRelease
		goto BarMinigame2
		}
	ArrowX := FindArrowX()
	if (ArrowX < 0)
		{
		gosub, PrecisionRelease
		goto BarMinigame2
		}
	MoveHudBarC(ArrowX)
	WantDown := (ArrowX > FishX) ? false : true
	goto PrecisionApply
	}

BarX := RunLeft + (RunWidth/2)
CastBlindN := 0
MoveHudBarSpan(RunLeft, RunWidth)
if (SpecialRod = "Dreambreaker" and !DbInv)
	{
	DllCall("QueryPerformanceCounter", "Int64*", DbNowQ)
	if (DbX0 < 0)
		{
		DbX0 := BarX
		if (!DbSeenQ)
			DbSeenQ := DbNowQ
		}
	else if (!DbMoveQ and Abs(BarX - DbX0) > Max(6, 12 * WindowHeight / 1440))
		DbMoveQ := DbNowQ
	}

; --- velocities -------------------------------------------------------------------------------
DllCall("QueryPerformanceCounter", "Int64*", tNowP)
if (PrevSampleT > 0)
	{
	dtP := (tNowP - PrevSampleT) / QpcFreq
	if (dtP > 0.0005)
		{
		rawBarVel := (BarX - PrevBarX) / dtP
		rawFishVel := (FishX - PrevFishX) / dtP
		if (Abs(FishX - PrevFishX) > 100)
			{
			rawFishVel := 0
			FishVel := 0
			}
		if (TargetIsNote)
			{
			rawFishVel := 0
			FishVel := 0
			}
		VsA := VelocitySmoothing
		if (SpecialRod = "Noiseform" and NoiseRate > 1 and VsA > 0 and VsA < 1)
			VsA := 1 - ((1 - VsA) ** NoiseRate)
		if (SpecialRod != "Noiseform" and VsA < 0.6)
			VsA := 0.6
		BarVel := VsA*rawBarVel + (1-VsA)*BarVel
		FishVel := VsA*rawFishVel + (1-VsA)*FishVel
		PrevBarX := BarX
		PrevFishX := FishX
		PrevSampleT := tNowP
		}
	}
else
	{
	PrevBarX := BarX
	PrevFishX := FishX
	PrevSampleT := tNowP
	}

PosError := BarX - FishX             
RelVel := BarVel - FishVel

SteadyTarget := (TargetIsNote and SpecialRod != "Halibut Harpoon")

if (SpecialRod = "Noiseform")
	{
	StopDist := Abs(RelVel) * StoppingDistanceMultiplier * 0.04
	if (StopDist < CaptureW * 0.01)
		StopDist := CaptureW * 0.01
	if (StopDist > RunWidth * 0.5)
		StopDist := RunWidth * 0.5
	}
else
	StopDist := Abs(RelVel) * StoppingDistanceMultiplier
if (SteadyTarget and SpecialRod != "Noiseform")
	StopDist := StopDist * 1.6

; --- reachable span ---------------------------------------------------------------------------
HalfW := RunWidth/2
MinReach := TrackLeft + HalfW
MaxReach := TrackRight - HalfW
CtrRs := (ResolutionScaling > 0) ? ResolutionScaling : 1
CtrZoneE := 36 / CtrRs
if (CtrZoneE > RunWidth * 0.35)
	CtrZoneE := RunWidth * 0.35
CtrZoneV := 120 / CtrRs
CtrHold := (SpecialRod != "Requiem" and !SteadyTarget
	and Abs(PosError) <= CtrZoneE and Abs(RelVel) <= CtrZoneV)
if (SpecialRod = "Noiseform" and (FishX < RunLeft or FishX > RunLeft + RunWidth))
	{
	if (NoiseFishFresh)
		NoiseStaleN := 0
	NoiseStuckN := 0
	NoiseStuckRel := 0
	NoiseLastBarX := Round(BarX)
	}


if (SpecialRod = "Castbound" and CastStatic
	and RunLeft > FishBarLeft + 2 and (RunLeft + RunWidth) < FishBarRight - 2
	and Abs(PosError) <= RunWidth * 0.5)
	{
	NoteAcc := NoteAcc + 0.5
	if (NoteAcc >= 1)
		{
		NoteAcc := NoteAcc - 1
		WantDown := true
		}
	else
		WantDown := false
	}
else if (FishX < MinReach)
	{
	WantDown := false
	}
else if (FishX > MaxReach)
	{
	WantDown := true
	}
else if (CtrHold)
	{
	CtrKp := 0.0122 * CtrRs
	CtrKd := 0.00488 * CtrRs
	if (dtP > 0 and dtP < 0.1)
		{
		CtrBias := CtrBias - (0.25 * CtrKp * PosError * dtP)
		if (CtrBias > 0.2)
			CtrBias := 0.2
		if (CtrBias < -0.2)
			CtrBias := -0.2
		}
	CtrDuty := 0.463 + CtrBias - (CtrKp * PosError) - (CtrKd * RelVel)
	if (CtrDuty < 0)
		CtrDuty := 0
	if (CtrDuty > 1)
		CtrDuty := 1
	CtrAcc := CtrAcc + CtrDuty
	if (CtrAcc >= 1)
		{
		CtrAcc := CtrAcc - 1
		WantDown := true
		}
	else
		WantDown := false
	}
else if (SpecialRod = "Castbound")
	{
	CastSdm := StoppingDistanceMultiplier
	if (CastSdm <= 0)
		CastSdm := 3.0
	CastStopA := 1000.0 * (3.0 / CastSdm)
	CastSigma := PosError + ((RelVel * Abs(RelVel)) / (2 * CastStopA))
	CastDead := RunWidth * 0.02
	if (CastDead < 2)
		CastDead := 2
	if (CastSigma > CastDead)
		WantDown := false
	else if (CastSigma < -CastDead)
		WantDown := true
	else
		WantDown := PrecisionDown
	}
else if (SpecialRod = "Halibut Harpoon" and TargetIsNote)
	{
	HaliSigma := PosError + (RelVel * 0.55)
	HaliDead := RunWidth * 0.02
	if (HaliDead < 2)
		HaliDead := 2
	if (HaliSigma > HaliDead)
		WantDown := false
	else if (HaliSigma < -HaliDead)
		WantDown := true
	else
		WantDown := PrecisionDown
	}
else if (FishX >= RunLeft and FishX <= (RunLeft + RunWidth))
	{
	if (SpecialRod = "Noiseform")
		{
		if (NoiseFishFresh)
			NoiseStaleN := 0
		else
			NoiseStaleN := NoiseStaleN + 1
		if (PrecisionDown and Abs(Round(BarX) - NoiseLastBarX) <= 2 and Abs(PosError) > 100)
			NoiseStuckN := NoiseStuckN + 1
		else if (Abs(Round(BarX) - NoiseLastBarX) > 2)
			{
			NoiseStuckN := 0
			NoiseLastBarX := Round(BarX)
			}
		if (NoiseStuckN >= NoiseN6 and !PrecisionDown)
			{
			NoiseStuckRel := NoiseStuckRel + 1
			if (NoiseStuckRel >= 12)
				{
				NoiseStuckN := 0
				NoiseStuckRel := 0
				NoiseLastBarX := Round(BarX)
				}
			}
		else
			NoiseStuckRel := 0
		ZoneSlack := 0
		if (NoiseZoneTgt >= 0)
			ZoneSlack := Round(CaptureW * 0.030)
		if (NoiseZoneTgt >= 0 and ZoneSlack > 0 and Abs(PosError) <= ZoneSlack)
			NoiseOnZoneN := NoiseOnZoneN + 1
		else
			NoiseOnZoneN := 0
		if (ZoneSlack > 0 and Abs(PosError) <= ZoneSlack)
			WantDown := ((PosError + (RelVel * 0.12)) > 0) ? false : true
		else
			{
			ControlOut := Kp*PosError + Kd*RelVel*0.60
			WantDown := (ControlOut > 0) ? false : true
			}
		}
	else if (SteadyTarget and Abs(PosError) <= NoteHoldZone(RunWidth))
		{
		NoteDuty := DutyAvg - (PosError / (NoteHoldZone(RunWidth) * 5.4)) - (BarVel * 0.0016)
		if (NoteDuty < 0)
			NoteDuty := 0
		if (NoteDuty > 1)
			NoteDuty := 1
		NoteAcc := NoteAcc + NoteDuty
		if (NoteAcc >= 1)
			{
			NoteAcc := NoteAcc - 1
			WantDown := true
			}
		else
			WantDown := false
		}
	else if (PosError < -StopDist)
		WantDown := true
	else if (PosError > StopDist)
		WantDown := false
	else
		{
		NoteAcc := 0
		CtrLook := (Kp > 0) ? (Kd / Kp) : 0.12
		if (CtrLook < 0.02)
			CtrLook := 0.02
		CtrMax := SteadyTarget ? 0.25 : 1.50
		if (CtrLook > CtrMax)
			CtrLook := CtrMax
		WantDown := ((PosError + (RelVel * CtrLook)) > 0) ? false : true
		}
	}
else
	{
	if (SpecialRod = "Noiseform")
		ControlOut := Kp*PosError + Kd*RelVel*0.60
	else if (SteadyTarget)
		{
		OutLook := (Kp > 0) ? (Kd / Kp) : 0.12
		if (OutLook < 0.02)
			OutLook := 0.02
		if (OutLook > 0.25)
			OutLook := 0.25
		ControlOut := Kp * (PosError + (RelVel * OutLook))
		}
	else
		ControlOut := Kp*PosError + Kd*RelVel
	WantDown := (ControlOut > 0) ? false : true
	}

PrecisionApply:
if (SpecialRod = "Noiseform" and WantDown and !PrecisionDown and NoiseFoundStreak < NoiseN6)
	WantDown := false
if (SpecialRod = "Noiseform" and NoiseStuckN >= NoiseN6)
	WantDown := false
if (SpecialRod = "Noiseform" and WantDown and !PrecisionDown and NoiseStaleN >= NoiseN6
	and !(NoiseZoneTgt >= 0 and NoiseZOK))
	{
	NoiseStaleBlk := NoiseStaleBlk + 1
	if (NoiseStaleBlk < NoiseN15)
		WantDown := false
	else
		NoiseStaleBlk := 0
	}
else
	NoiseStaleBlk := 0
if (SpecialRod = "Dreambreaker" and !DbInv and DbSeenQ)
	{
	DllCall("QueryPerformanceCounter", "Int64*", DbNowQ)
	if ((DbMoveQ and (DbNowQ - DbMoveQ) / QpcFreq >= 1.4) or ((DbNowQ - DbSeenQ) / QpcFreq >= 3.1))
		DbInv := true
	}
if (SpecialRod = "Dreambreaker" and DbInv)
	WantDown := !WantDown
if (WantDown)
	gosub, PrecisionHold
else
	gosub, PrecisionRelease
goto BarMinigame2

PrecisionHold:
if (SpecialRod = "Stellarwave Melody" and (SwPressK or SwWantK))
	return
if (SwClickFirst())
	{
	if (PrecisionDown or (GetKeyState("LButton") and !SwPressK))
		{
		send {lbutton up}
		PrecisionDown := false
		DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
		}
	return
	}
if (!PrecisionDown)
	{
	SwMinRel := (SpecialRod = "Requiem") ? ReelMinRelease : ((SpecialRod = "Stellarwave Melody" and SwPhase) ? ((SwDwell and (SwRetryClicks ? (SwPressN + SwRetry < 3 and SwClickSlot != SwOverS) : !SwPressN)) ? 500 : (SwPreK ? 320 : ((SwFastClicks or SwMaxSigns) ? 250 : 100))) : 0)
	if (SwMinRel > 0 and PrecisionUpAt)
		{
		DllCall("QueryPerformanceCounter", "Int64*", ReelNow)
		if (((ReelNow - PrecisionUpAt) * 1000.0 / QpcFreq) < SwMinRel)
			return
		}
	if (SwPreK)
		{
		SwPreEnd("reel")
		return
		}
	if (SwParkAt and SwParkWait())
		return
	send {lbutton down}
	PrecisionDown := true
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionDownAt)
	PrecisionResendAt := PrecisionDownAt
	return
	}
DllCall("QueryPerformanceCounter", "Int64*", ReelNow)
if (!GetKeyState("LButton") or ((ReelNow - PrecisionResendAt) * 1000.0 / QpcFreq) >= 400)
	{
	if (SwPreK)
		{
		SwPreEnd("reel")
		return
		}
	if (SwParkAt and SwParkWait())
		return
	send {lbutton down}
	PrecisionResendAt := ReelNow
	}
return

PrecisionRelease:
if (PrecisionDown)
	{
	SwMinHold := (SpecialRod = "Requiem") ? ReelMinHold : ((SpecialRod = "Stellarwave Melody" and SwPhase) ? 250 : 0)
	if (SwMinHold > 0 and PrecisionDownAt)
		{
		DllCall("QueryPerformanceCounter", "Int64*", ReelNow)
		if (((ReelNow - PrecisionDownAt) * 1000.0 / QpcFreq) < SwMinHold)
			return
		}
	send {lbutton up}
	PrecisionDown := false
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	return
	}
if (GetKeyState("LButton") and !SwPressK)
	send {lbutton up}
return

StabilizeBurst:
if (SpecialRod = "Requiem" or (SpecialRod = "Stellarwave Melody" and SwPhase))
	return
gosub, CaptureFishBar
if (!BarPresent() and !FishLineVisible() and FindArrowX() < 0)
	return
if (UiHandsOff(true))
	return
loop, %StabilizerLoop%
	{
	send {lbutton down}
	send {lbutton up}
	}
return

;====================================================================================================;

BarMinigameOver:
if (SwPressK)
	SwPressEnd()
SwWantK := 0
NoFishAt := 0
BarLiveL := -1
BarLiveR := -1
BarLiveMiss := 0
BarWLive := -1
BarLiveOnlyAt := 0
NoFishAt := 0
if (!MgCastCharged and GetKeyState("LButton"))
	gosub, CastChargeCheck
send {lbutton up}
send {rbutton up}
PrecisionDown := false
MgInPlay := false
WhCatches := WhCatches + 1
KbCatches := KbCatches + 1
KbOcrCatches := KbOcrCatches + 1
WhLastCatchTick := A_TickCount
WhStalled := false
if (WebhookOnCatch)
	WhEvent("catch")
settimer, BarCalculationFailsafe, off
send {lbutton up}
send {rbutton up}
if (MgCastCharged)
	{
	MgCastCharged := false
	if (RodSlotKey != "")
		ForceReEquip := true
	}

tooltip, Current Task: Restarting, %TooltipX%, %Tooltip7%, 7
tooltip, , , , 8
tooltip, , , , 10
tooltip, , , , 11
tooltip, , , , 12
tooltip, , , , 13
tooltip, , , , 15
gosub, HideHud
if (AdaptiveCast)
	{
	AcMs := AdaptiveCastMs
	if AcMs is not number
		AcMs := 150
	; negative = cast sooner: one clear frame is enough and there is no extra wait
	; (the fight was already ended earlier - see BarLostLim)
	AcNeed := (AcMs < 0) ? 1 : 2
	AcT0 := A_TickCount
	AcClear := 0
	while (MacroRunning and A_TickCount - AcT0 < 4000)
		{
		gosub, CaptureFishBar
		AcVis := (SpecialRod = "Tranquility") ? ManiaVisible() : (BarPresent() or FishLineVisible())
		AcClear := AcVis ? 0 : AcClear + 1
		if (AcClear >= AcNeed)
			break
		Sleep, 15
		}
	if (AcMs < 0)
		tooltip, Action: Casting right away (%AcMs%ms - early), %TooltipX%, %Tooltip8%, 8
	else
		{
		tooltip, Action: Casting %AcMs%ms after the minigame closed, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(AcMs)
		}
	}
else
	Sleep, % Tm(RestartDelay)
goto RestartMacro

;====================================================================================================;

KeeperRun:

KbBusy := true
SetBatchLines, -1
KbLastResult := ""
KbStatus := "opening"
KbRecharged := 0
KbOpenCol := -1
KbRelicOn := false
MouseGetPos, KbSaveX, KbSaveY
send {lbutton up}
send {rbutton up}
tooltip, Current Task: Keeperbound Recharge, %TooltipX%, %Tooltip7%, 7
KbPreV := KeeperPreDelay
if KbPreV is number
	{
	if (KbPreV > 0)
		{
		tooltip, Action: Waiting %KbPreV% ms before recharging, %TooltipX%, %Tooltip8%, 8
		Sleep, % Tm(KbPreV)
		}
	}

gosub, MgOnScreenChk
if (MgOnScreen or MgInPlay)
	{
	KbPostponeN := KbPostponeN + 1
	KbOcrCatches := 9999
	KbLastResult := "postponed - a minigame was on screen"
	KbStatus := "postponed"
	tooltip, , , , 8
	KbBusy := false
	return
	}
KbPostponeN := 0

if (KeeperRelicKey = "")
	{
	KbLastResult := "no relic key set"
	goto KeeperBail
	}
if (RobloxHwnd and !WinActive("ahk_id " . RobloxHwnd))
	{
	WinActivate, ahk_id %RobloxHwnd%
	WinWaitActive, ahk_id %RobloxHwnd%, , % TA("kbfocusto", 3)
	Sleep, % Tm(TA("kbfocus", 100))
	}

gosub, KeeperClearDialog

KbWant := Round(KeeperRecharges)
if (KbWant < 1)
	KbWant := 1
if (KbWant > 20)
	KbWant := 20

KbManual := (KbSpot("enchant", KbEx, KbEy) and KbSpot("confirm", KbCx, KbCy))
KbStatus := "recharging"

if (KbManual)
	{
	tooltip, Action: Open Inventory, %TooltipX%, %Tooltip8%, 8
	KbKey(KeeperInvKey)
	Sleep, % Tm(KeeperOpenDelay)

	tooltip, Action: Equip Relic, %TooltipX%, %Tooltip8%, 8
	KbKey(KeeperRelicKey)
	KbRelicOn := true
	Sleep, % Tm(KeeperStepDelay)
	KbOpenCol := -1
	PixelGetColor, KbOpenCol, %KbEx%, %KbEy%, RGB
	if (ErrorLevel)
		KbOpenCol := -1

	KbI := 0
	while (KbI < KbWant and MacroRunning)
		{
		KbI++
		tooltip, Action: Enchant Rod, %TooltipX%, %Tooltip8%, 8
		KbTapSaved(KbEx, KbEy)
		Sleep, % Tm(KeeperStepDelay)
		tooltip, Action: Confirm, %TooltipX%, %Tooltip8%, 8
		KbTapSaved(KbCx, KbCy)
		Sleep, % Tm(KeeperStepDelay)
		KbRecharged++
		if (KbI < KbWant)
			Sleep, % Tm(KeeperBetweenDelay)
		}
	KbLastResult := "pressed " . KbRecharged . " of " . KbWant
	goto KeeperBail
	}

; ---- no saved positions: find the buttons instead ------------------------------------------
tooltip, Action: Open Inventory, %TooltipX%, %Tooltip8%, 8
if (!KbWaitFor("enchant", KbEx, KbEy, TA("kbinv1", 700)))
	{
	KbKey(KeeperInvKey)
	if (!KbWaitFor("enchant", KbEx, KbEy, KeeperOpenDelay + TA("kbinv2", 3000)))
		{
		KbKey(KeeperInvKey)
		if (!KbWaitFor("enchant", KbEx, KbEy, KeeperOpenDelay + TA("kbinv2", 3000)))
			{
			KbLastResult := "could not open the inventory"
			goto KeeperBail
			}
		}
	}

tooltip, Action: Equip Relic, %TooltipX%, %Tooltip8%, 8
KbKey(KeeperRelicKey)
KbRelicOn := true
Sleep, % Tm(KeeperStepDelay)

KbGuard := 0
Loop
	{
	KbGuard++
	if (KbGuard > 24 or !MacroRunning or KbRecharged >= KbWant)
		break
	tooltip, Action: Enchant Rod, %TooltipX%, %Tooltip8%, 8
	; remember how the Enchant button looks once the inventory has settled - closing is then checked with
	; one pixel instead of screen searches
	if (KbOpenCol < 0)
		KbOpenCol := KbSteadyCol(KbEx, KbEy)
	KbTap(KbEx, KbEy)
	if (!KbWaitFor("confirm", KbCx, KbCy, TA("kbconfto", 3500)))
		{
		KbLastResult := "Enchant Rod did nothing - try setting the button positions"
		break
		}
	Sleep, % Tm(TA("kbconfirm", 120))
	tooltip, Action: Confirm, %TooltipX%, %Tooltip8%, 8
	KbTap(KbCx, KbCy)
	Sleep, % Tm(KeeperStepDelay)
	if (!KbGone("confirm", TA("kbgone", 3000)))
		gosub, KeeperClearDialog
	KbRecharged++
	KbLastResult := ""
	if (KbRecharged < KbWant)
		Sleep, % Tm(KeeperBetweenDelay)
	}
if (KbLastResult != "")
	KbLastResult := "recharged " . KbRecharged . " of " . KbWant . " - " . KbLastResult
else
	KbLastResult := "recharged " . KbRecharged . " of " . KbWant

KeeperBail:
tooltip, Action: Close Inventory, %TooltipX%, %Tooltip8%, 8
KbClosed := false
KbFcOk := KbSpot("enchant", KbFx, KbFy)
if (!KbFcOk and KbEx != "" and KbEx >= 0)
	{
	; no saved position: the Enchant button found on screen this time
	KbFx := KbEx
	KbFy := KbEy
	KbFcOk := true
	}
KbFcR := 0
if (KbOpenCol >= 0 and KbFcOk)
	KbFcR := KbFastClose(KbFx, KbFy, KbOpenCol)
KbClosed := (KbFcR = 1)
if (!KbClosed)
	{
	; only the Enchant button in the spot it was in counts - something else on screen can look like one,
	; and pressing the key on that reopened the inventory that had just closed
	KbNx := (KbEx != "" and KbEx >= 0) ? KbEx : -1
	KbNy := (KbNx >= 0) ? KbEy : -1
	KbShut := false
	; the key was already pressed - the inventory may just be slow to go, so wait for that first
	if (KbFcR = 2 and KbGone("enchant", TA("kbclose", 1200), KbNx, KbNy))
		KbShut := true
	if (!KbShut)
		gosub, KeeperClearDialog
	KbGuard := 0
	while (!KbShut and KbGuard < 3)
		{
		KbGuard++
		; press the key only when the button is seen in its place twice in a row
		KbOpenNow := KbFind("enchant", KbGx, KbGy, "", KbNx, KbNy)
		if (KbOpenNow)
			{
			Sleep, 120
			KbOpenNow := KbFind("enchant", KbGx, KbGy, "", KbNx, KbNy)
			}
		if (!KbOpenNow)
			{
			KbShut := true
			break
			}
		KbKey(KeeperInvKey)
		if (KbGone("enchant", TA("kbclose", 1200), KbNx, KbNy))
			KbShut := true
		}
	if (!KbShut)
		KbLastResult .= " (inventory still open)"
	}

; pressing the rod key while the rod is still in hand would put it away (and the next cast would do
; nothing), so only switch back when the relic was taken out
if (KbRelicOn)
	{
	tooltip, Action: Select Rod, %TooltipX%, %Tooltip8%, 8
	if (RodSlotKey != "")
		{
		KbBarWas := KbBarShown()
		send {%RodSlotKey%}
		if (KbBarWas = 0)
			{
			; the power bar shows as soon as the rod is back in hand - go on then, not after a fixed wait
			KbSelT := A_TickCount
			while (A_TickCount - KbSelT < Tm(TA("kbselect", 450)))
				{
				Sleep, 15
				if (KbBarShown() = 1)
					{
					Sleep, % Tm(TA("kbrodsettle", 100))
					break
					}
				}
			}
		else
			Sleep, % Tm(TA("kbselect", 450))
		}
	else
		{
		ForceReEquip := true
		KbLastResult .= " - set the Rod slot key so it can switch back to the rod"
		}
	}
MouseMove, KbSaveX, KbSaveY
tooltip, , , , 8
KbStatus := (KbRecharged > 0) ? "done" : "failed"
WhEvent("keeper", ((KbStatus = "done") ? "Done: " : "Failed: ") . KbLastResult)
KbCatches := 0
KbOcrCatches := 0
KbGoodPct := ""
KbSuspect := false
KbBusy := false
SetBatchLines, -1
return

;====================================================================================================;

KeeperClearDialog:
KbClr := 0
while (KbClr < 4 and KbFind("confirm", KbCx, KbCy))
	{
	; a confirm box that is just closing goes away by itself - only press its red button if it stays
	if (KbClr = 0 and KbGone("confirm", TA("kbclearwait", 250)))
		break
	KbClr++
	if (KbFind("confirm", KbRx, KbRy, "red"))
		KbTap(KbRx, KbRy)
	else
		break
	KbGone("confirm", TA("kbclear", 900))
	}
return

;====================================================================================================;

AquariumRun:

AqBusy := true
SetBatchLines, -1
AqBuys := 0
AqUses := 0
AqUseOnly := false
AqHoverOk := false
AqLastResult := ""
AqStatus := "opening"
MouseGetPos, AqSaveX, AqSaveY
send {lbutton up}
send {rbutton up}
tooltip, Current Task: Auto Aquarium, %TooltipX%, %Tooltip7%, 7
tooltip, Action: Open Aquariums, %TooltipX%, %Tooltip8%, 8

if (RobloxHwnd)
	{
	WinActivate, ahk_id %RobloxHwnd%
	WinWaitActive, ahk_id %RobloxHwnd%, , % TA("aqfocusto", 3)
	Sleep, % Tm(TA("aqfocus", 350))
	}

if (!AqPanelSure())
	{
	AqTap(AqNavX, AqNavY)
	AqWaitPanel(1)
	}
if (!AqPanelSure())
	AqRecoverRow()
if (!AqPanelSure())
	{
	AqLastResult := "could not find the fish food panel"
	AqStatus := "failed"
	WhEvent("aquarium", "Failed: " . AqLastResult)
	MouseMove, AqSaveX, AqSaveY
	tooltip, , , , 8
	AqNextTick := A_TickCount + (Round(AquariumEveryMin) * 60000)
	AqBusy := false
	SetBatchLines, -1
	return
	}

AqStatus := "feeding"
AqCap := Round(AquariumFoodCount)
if (AqCap < 10)
	AqCap := 10

tooltip, Action: Scroll To Start, %TooltipX%, %Tooltip8%, 8
AqMeasurePitch()

AqUseOnly := false
gosub, AquariumSweep

if (AqBuys > 0 and MacroRunning)
	{
	tooltip, Action: Use New Fish Food, %TooltipX%, %Tooltip8%, 8
	AqUseOnly := true
	gosub, AquariumSweep
	}

tooltip, Action: Back To Start, %TooltipX%, %Tooltip8%, 8
AqScrollHome()

AqLastResult := "bought " . AqBuys . ", used " . AqUses
AqStatus := "done"

AquariumClose:
tooltip, Action: Close Aquariums, %TooltipX%, %Tooltip8%, 8
if (AqPanelSure())
	{
	AqTap(AqNavX, AqNavY)
	AqWaitPanel(0)
	}
MouseMove, AqSaveX, AqSaveY
tooltip, , , , 8
AqNextTick := A_TickCount + (Round(AquariumEveryMin) * 60000)
if (AqStatus = "done")
	WhEvent("aquarium", "Done: " . AqLastResult)
else
	WhEvent("aquarium", "Stopped: " . ((AqLastResult != "") ? AqLastResult : AqStatus))
AqBusy := false
SetBatchLines, -1
return

;====================================================================================================;

;====================================================================================================;

AquariumSweep:
AqDone := 0
AqHitShop := false
AqScrollHome()

AqShiftAcc := 0
AqSeenMax := -999999
AqHalf := AqCardPitch // 2
if (AqHalf < 20)
	AqHalf := 20
AqStep := 1
AqStall := 0
AqGuard := 0
AqScan()
Loop
	{
	AqGuard++
	if (AqGuard > 60 or !MacroRunning or AqDone >= AqCap)
		break
	gosub, AquariumHandleNew
	if (AqHitShop)
		break
	AqPrevLeft := AqLeftX()
	AqOldX := []
	AqOldN := AqBtnN
	AqI := 1
	while (AqI <= AqOldN)
		{
		AqOldX.Push(AqBtnCX[AqI])
		AqI++
		}
	tooltip, Action: Next Fish Food, %TooltipX%, %Tooltip8%, 8
	if (!AqWheel(AqStep, 1))
		break
	if (AqScan() < 1)
		{
		AqBack := 0
		while (AqBack < AqStep + 3)
			{
			AqBack++
			if (!AqWheel(1, -1))
				break
			if (AqScan() >= 1)
				break
			}
		if (AqBtnN >= 1)
			{
			AqShiftAcc := AqShiftAcc + AqShiftBetween(AqOldX, AqOldN, AqBtnCX, AqBtnN, AqCardPitch)
			gosub, AquariumHandleNew
			}
		break
		}
	if (AqLeftX() = AqPrevLeft)
		{
		AqStall++
		if (AqStall >= 5)
			break
		}
	else
		AqStall := 0
	AqMoved := AqShiftBetween(AqOldX, AqOldN, AqBtnCX, AqBtnN, AqCardPitch)
	AqShiftAcc := AqShiftAcc + AqMoved
	}
return

;====================================================================================================;

AquariumHandleNew:
AqLstN := AqBtnN
AqLstX := []
AqLstY := []
AqLstK := []
AqI := 1
while (AqI <= AqLstN)
	{
	AqLstX.Push(AqBtnCX[AqI])
	AqLstY.Push(AqBtnCY[AqI])
	AqLstK.Push(AqBtnKind[AqI])
	AqI++
	}

AqI := 1
while (AqI <= AqLstN)
	{
	if (!MacroRunning or AqDone >= AqCap)
		break
	AqCx := AqLstX[AqI]
	AqCy := AqLstY[AqI]
	AqKind := AqLstK[AqI]
	AqContentX := AqCx + AqShiftAcc
	if (AqContentX <= AqSeenMax + AqHalf)
		{
		AqI++
		continue
		}
	AqSeenMax := AqContentX
	if (AqKind = "buy" and AqUseOnly)
		{
		AqHitShop := true
		break
		}
	if (AqKind = "buy" and AqBuys >= AquariumMaxBuys)
		{
		AqI++
		continue
		}
	AqDone++
	if (AqKind = "buy")
		{
		tooltip, Action: Buy Fish Food, %TooltipX%, %Tooltip8%, 8
		AqBuys++
		}
	else
		{
		tooltip, Action: Use Fish Food, %TooltipX%, %Tooltip8%, 8
		AqUses++
		}
	AqTap(AqCx, AqCy)
	Sleep, % Tm(AquariumStepDelay)
	AqScan()
	AqI++
	}
AqScan()
return

;====================================================================================================;

StopSweep:
StopSweepTicks++
Loop, 10
	tooltip, , , , % A_Index + 6
gosub, HideHud
if (StopSweepTicks >= 60)
	{
	settimer, StopSweep, off
	gosub, RefreshHints
	}
return

;====================================================================================================;

Idle:

if (SwPressK)
	SwPressEnd()
SwWantK := 0
send {lbutton up}
send {rbutton up}
PrecisionDown := false
if (SwPreK)
	SwPreEnd("stop")
AqBusy := false
KbBusy := false
MacroPreview := false
MgInPlay := false
settimer, WhTick, off
if (WhStartTick)
	WhEvent("stop")
WhStartTick := 0
settimer, runtime, off
settimer, NavigationShakeFailsafe, off
settimer, BarCalculationFailsafe, off

GuiControl, 1:, StartStopDisplay, ▶ Start
gosub, RefreshRunChip

send {lbutton up}
send {rbutton up}
send {shift up}

tooltip, , , , 6
tooltip, , , , 7
tooltip, , , , 8
tooltip, , , , 9
tooltip, , , , 10
tooltip, , , , 11
tooltip, , , , 12
tooltip, , , , 13
tooltip, , , , 14
tooltip, , , , 15
tooltip, , , , 16
gosub, HideHud
gosub, RefreshHints

return

;====================================================================================================;

RefreshHints:
if (DetTesting)
	return
if (MacroRunning)
	{
	tooltip, Press "%StartStopKey%" to Stop, %TooltipX%, %Tooltip4%, 4
	tooltip, Press "%ReloadKey%" to Reload, %TooltipX%, %Tooltip5%, 5
	tooltip, , , , 6
	}
else
	{
	tooltip, Press "%StartStopKey%" to Start, %TooltipX%, %Tooltip4%, 4
	tooltip, Press "%ReloadKey%" to Reload, %TooltipX%, %Tooltip5%, 5
	tooltip, Press "%ExitKey%" to Exit, %TooltipX%, %Tooltip6%, 6
	}
return

;====================================================================================================;

EnsureConfigFiles:

if !InStr(FileExist(ProfilesDir), "D")
	FileCreateDir, %ProfilesDir%

if !FileExist(DefaultProfileFile)
	gosub, BuildDefaultProfile

if !FileExist(SettingsFile)
	{
	IniWrite, Default, %SettingsFile%, Profiles, ActiveProfile
	IniWrite, p, %SettingsFile%, Hotkeys, StartStop
	IniWrite, o, %SettingsFile%, Hotkeys, Reload
	IniWrite, m, %SettingsFile%, Hotkeys, Exit
	IniWrite, 0, %SettingsFile%, GUI, AlwaysOnTop
	IniWrite, 0, %SettingsFile%, GUI, KeepOpen
	IniWrite, 0, %SettingsFile%, GUI, AutoSave
	IniWrite, 0, %SettingsFile%, Meta, FirstRunDone
	}

return

;====================================================================================================;

DFAccessInit:
DFLocked := false
DFLockReason := ""
DFKill := false
IniRead, DFInstallID, %SettingsFile%, Access, InstallID, %A_Space%
if (DFInstallID = "" or StrLen(DFInstallID) < 8)
	{
	Random,, % A_TickCount
	; always has a letter, so it is never read as a number
	DFInstallID := ""
	while !RegExMatch(DFInstallID, "[a-f]")
		{
		DFInstallID := ""
		Loop 16
			{
			Random, rr, 0, 15
			DFInstallID .= SubStr("0123456789abcdef", rr + 1, 1)
			}
		}
	IniWrite, %DFInstallID%, %SettingsFile%, Access, InstallID
	}
IniRead, DFTrusted, %SettingsFile%, Access, Trusted, 0
DFTrusted := (DFTrusted = 1) ? 1 : 0
IniRead, DFReqKeyCache, %SettingsFile%, Access, ReqKeyCache, 0
gosub, DFAccessCheck
SetTimer, DFAccessCheck, 180000
gosub, DFInstallPing
DFAccessReady := true
if (DFKill or DFBlockedNow)
	gosub, DFBlockedExit
return

; blocked or turned off by the owner: the window does not stay open
DFBlockedExit:
SetTimer, DFAccessCheck, Off
if (MacroRunning)
	gosub, DFForceStop
try DFFormReq.WaitForResponse(5)
try DFPingReq.WaitForResponse(5)
MsgBox, 0x41030, DeepFish, %DFLockReason%
ExitApp

; install log: on start (and when a key is added) posts the Install ID, keyed or not, and the version to the owner's channel
DFInstallPing:
; the owner's Google Form (one short-answer question): "id|keyed|version|UTC time" - the publisher reads it back from the sheet
if (InStr(DFInstallForm, "/formResponse|entry."))
	{
	DFFormP := StrSplit(DFInstallForm, "|")
	try
		{
		DFFormReq := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		DFFormReq.SetTimeouts(4000, 4000, 4000, 6000)
		DFFormReq.Open("POST", DFFormP[1], true)
		DFFormReq.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
		DFFormReq.Send(DFFormP[2] . "=" . DFInstallID . "%7C" . (DFTrusted ? 1 : 0) . "%7C" . DFVersion . "%7C" . A_NowUTC)
		}
	catch e
		DFFormReq := ""
	}
if (DFInstallHook = "" or !InStr(DFInstallHook, "/api/webhooks/"))
	return
DFPingF := WhField("Install ID", DFInstallID) . "," . WhField("Version", "v" . DFVersion . "  (build " . DFModBuild . ")")
DFPingF .= "," . WhField("Blocked", DFBlockedNow ? "yes" : "no")
DFPingJ := "{""username"":""DeepFish installs"",""embeds"":[{""title"":""" . (DFTrusted ? "Keyed install" : "NOT keyed install") . """,""color"":" . (DFTrusted ? 3066993 : 15158332) . ",""fields"":[" . DFPingF . "],""timestamp"":""" . WhStamp() . """}]}"
try
	{
	DFPingReq := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	DFPingReq.SetTimeouts(4000, 4000, 4000, 6000)
	DFPingReq.Open("POST", DFInstallHook, true)
	DFPingReq.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
	DFPingReq.Send(DFPingJ)
	}
catch e
	DFPingReq := ""
return

DFAccessCheck:
DFAccTxt := ""
DFBlkTxt := ""
DFReach := false
if (DFUpdateRepo != "")
	{
	try
		{
		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.SetTimeouts(3000, 3000, 3000, 3000)
		whr.Open("GET", "https://raw.githubusercontent.com/" . DFUpdateRepo . "/HEAD/access.txt?t=" . A_TickCount, false)
		whr.Send()
		if (whr.Status = 200)
			{
			DFAccTxt := whr.ResponseText
			DFReach := true
			}
		else if (whr.Status = 404)
			DFReach := true
		}
	catch e
		DFReach := false
	try
		{
		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.SetTimeouts(3000, 3000, 3000, 3000)
		whr.Open("GET", "https://raw.githubusercontent.com/" . DFUpdateRepo . "/HEAD/blocked.txt?t=" . A_TickCount, false)
		whr.Send()
		if (whr.Status = 200)
			DFBlkTxt := whr.ResponseText
		}
	catch e
		DFBlkTxt := DFBlkTxt
	}
DFKill := false
DFReqKey := DFReqKeyCache
if (DFReach)
	{
	DFKill := (InStr(DFAccTxt, "kill=1") ? true : false)
	DFReqKey := (InStr(DFAccTxt, "requirekey=1") ? 1 : 0)
	if (DFReqKey != DFReqKeyCache)
		{
		DFReqKeyCache := DFReqKey
		IniWrite, %DFReqKey%, %SettingsFile%, Access, ReqKeyCache
		}
	}
DFBlockedNow := false
Loop, Parse, DFBlkTxt, `n, `r
	{
	v := Trim(A_LoopField)
	if (v != "" and v = DFInstallID)
		DFBlockedNow := true
	}
DFLocked := false
DFLockReason := ""
if (DFKill)
	{
	DFLocked := true
	DFLockReason := "The macro has been turned off by the owner."
	}
else if (DFBlockedNow)
	{
	DFLocked := true
	DFLockReason := "Your access to this macro has been turned off."
	}
else if (DFReqKey = 1 and !DFTrusted)
	{
	DFLocked := true
	DFLockReason := "This macro needs a key.`n`nClick ""Add key"" (bottom left) and enter the key the owner gave you.`n`nYour Install ID:  " . DFInstallID
	}
if ((DFKill or DFBlockedNow) and DFAccessReady)
	gosub, DFBlockedExit
if (DFLocked and MacroRunning)
	gosub, DFForceStop
return

DFForceStop:
MacroRunning := false
MacroPreview := false
GuiControl, 1:, StartStopDisplay, ▶ Start
gosub, RefreshRunChip
settimer, runtime, off
settimer, NavigationShakeFailsafe, off
settimer, BarCalculationFailsafe, off
send {lbutton up}
send {rbutton up}
send {shift up}
TrayTip, DeepFish, %DFLockReason%, 5
return

AddKeyClick:
DFKeyPrompt := "Your Install ID (send this to the owner to get a key):`n`n" . DFInstallID . "`n`nPaste the key you were given:"
InputBox, DFKeyIn, DeepFish - Add key, %DFKeyPrompt%, , 420, 230
if (ErrorLevel)
	return
DFKeyIn := Trim(DFKeyIn)
if (DFKeyIn = "")
	return
if (DFKeySalt = "")
	{
	MsgBox, 0x1030, DeepFish, Keys are not set up for this build yet. Ask the owner.
	return
	}
if (DFKeyNorm(DFKeyIn) = DFKeyNorm(DFKeyExpected(DFInstallID)))
	{
	DFTrusted := 1
	IniWrite, 1, %SettingsFile%, Access, Trusted
	gosub, DFAccessCheck
	gosub, DFInstallPing
	MsgBox, 0x1040, DeepFish, Key accepted - you are now trusted on this PC.
	}
else
	MsgBox, 0x1030, DeepFish, That key is not valid for this PC.`n`nMake sure the owner made it from this exact Install ID:`n`n%DFInstallID%
return

DFKeyExpected(id) {
	global DFKeySalt
	h := SHA256Hex(id . "|" . DFKeySalt)
	x := SubStr(h, 1, 12)
	return "DF-" . SubStr(x, 1, 4) . "-" . SubStr(x, 5, 4) . "-" . SubStr(x, 9, 4)
}

DFKeyNorm(k) {
	k := RegExReplace(k, "[^0-9A-Za-z]", "")
	StringUpper, k, k
	return k
}

SHA256Hex(str) {
	n := StrPut(str, "UTF-8") - 1
	VarSetCapacity(buf, (n < 1) ? 1 : n, 0)
	StrPut(str, &buf, "UTF-8")
	return CryptHashHex(&buf, n)
}

CryptHashHex(pData, nData) {
	hProv := 0
	hHash := 0
	if (!DllCall("advapi32\CryptAcquireContextW", "Ptr*", hProv, "Ptr", 0, "Ptr", 0, "UInt", 24, "UInt", 0xF0000000))
		return ""
	if (!DllCall("advapi32\CryptCreateHash", "Ptr", hProv, "UInt", 0x800C, "Ptr", 0, "UInt", 0, "Ptr*", hHash))
		{
		DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
		return ""
		}
	DllCall("advapi32\CryptHashData", "Ptr", hHash, "Ptr", pData, "UInt", nData, "UInt", 0)
	size := 32
	VarSetCapacity(hash, size, 0)
	DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", &hash, "UInt*", size, "UInt", 0)
	hex := ""
	Loop % size
		{
		b := NumGet(hash, A_Index - 1, "UChar")
		hex .= SubStr("0" . Format("{:X}", b), -1)
		}
	DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
	DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
	return hex
}

OverlayHideTick:
OvWant := MacroRunning and (HideOverlay or (SwPassiveHide and ((SwPassive and SpecialRod = "Stellarwave Melody") or PassiveAll)))
TipWant := OvWant or (InfoPanelOn and MacroRunning)
if (TipWant != TipsHidden)
	{
	TipsHidden := TipWant ? true : false
	OverlaySetHidden(TipsHidden)
	}
if (OvWant = OverlayHidden)
	return
OverlayHidden := OvWant ? true : false
if (OverlayHidden)
	gosub, HideHud
return

OverlaySetHidden(hide) {
	static hook := 0, cb := 0, cbt := 0, cbtCb := 0
	pid := DllCall("GetCurrentProcessId")
	if (hide and !hook)
		{
		if (!cb)
			cb := RegisterCallback("OverlayWinEvent")
		hook := DllCall("SetWinEventHook", "UInt", 0x8000, "UInt", 0x800E, "Ptr", 0, "Ptr", cb, "UInt", pid, "UInt", 0, "UInt", 0, "Ptr")
		}
	else if (!hide and hook)
		{
		DllCall("UnhookWinEvent", "Ptr", hook)
		hook := 0
		}
	; clearing a tooltip destroys its window, so new text makes a new one - the hook above only hears about it
	; after it was drawn once (a flicker). This one runs while the window is being made, so it starts invisible.
	if (hide and !cbt)
		{
		if (!cbtCb)
			cbtCb := RegisterCallback("OverlayCbt", "Fast")
		cbt := DllCall("SetWindowsHookEx", "Int", 5, "Ptr", cbtCb, "Ptr", 0, "UInt", DllCall("GetCurrentThreadId", "UInt"), "Ptr")
		}
	else if (!hide and cbt)
		{
		DllCall("UnhookWindowsHookEx", "Ptr", cbt)
		cbt := 0
		}
	dhw := A_DetectHiddenWindows
	DetectHiddenWindows, On
	WinGet, ids, List, ahk_class tooltips_class32 ahk_pid %pid%
	Loop, %ids%
		{
		h := ids%A_Index%
		if (hide)
			{
			OverlayTipGuard(h)
			WinSet, Transparent, 0, ahk_id %h%
			}
		else
			{
			WinSet, Transparent, Off, ahk_id %h%
			; it was kept hidden - show it again (a cleared tooltip has no window, so these all have text)
			DllCall("ShowWindow", "Ptr", h, "Int", 8)
			}
		}
	DetectHiddenWindows, %dhw%
}

; a tooltip window being made while tooltips are hidden - guarded before it is ever shown
OverlayCbt(nCode, wParam, lParam) {
	global TipsHidden
	if (nCode = 3 and TipsHidden)
		{
		VarSetCapacity(cls, 128, 0)
		DllCall("GetClassName", "Ptr", wParam, "Str", cls, "Int", 64)
		if (cls = "tooltips_class32")
			OverlayTipGuard(wParam)
		}
	return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam, "Ptr")
}

; while tooltips are hidden a guarded tooltip never shows: "show" is taken out of every move it makes.
; Alpha 0 alone flickered - the tooltip sets its own alpha back to full each time it shows.
OverlayTipGuard(h) {
	global OverlayTipOld
	static proc := 0
	if (!IsObject(OverlayTipOld))
		OverlayTipOld := {}
	if (OverlayTipOld.HasKey(h))
		return
	if (!proc)
		proc := RegisterCallback("OverlayTipProc", "Fast")
	old := DllCall((A_PtrSize = 8) ? "SetWindowLongPtr" : "SetWindowLong", "Ptr", h, "Int", -4, "Ptr", proc, "Ptr")
	if (old)
		OverlayTipOld[h] := old
	if (DllCall("IsWindowVisible", "Ptr", h))
		DllCall("ShowWindow", "Ptr", h, "Int", 0)
}

OverlayTipProc(h, msg, wParam, lParam) {
	global TipsHidden, OverlayTipOld
	old := OverlayTipOld[h]
	if (msg = 0x46 and TipsHidden)
		{
		; WM_WINDOWPOSCHANGING: drop SWP_SHOWWINDOW
		off := (A_PtrSize = 8) ? 32 : 24
		fl := NumGet(lParam + 0, off, "UInt")
		if (fl & 0x40)
			NumPut(fl & ~0x40, lParam + 0, off, "UInt")
		}
	r := DllCall("CallWindowProc", "Ptr", old, "Ptr", h, "UInt", msg, "Ptr", wParam, "Ptr", lParam, "Ptr")
	if (msg = 0x82)
		OverlayTipOld.Delete(h)
	return r
}

OverlayWinEvent(hHook, event, hwnd, idObject, idChild, thread, time) {
	global TipsHidden
	if (!TipsHidden or idObject != 0 or !hwnd)
		return
	DetectHiddenWindows, On
	WinGetClass, c, ahk_id %hwnd%
	if (c = "tooltips_class32")
		WinSet, Transparent, 0, ahk_id %hwnd%
}

DFCheckForUpdate:
SetTimer, DFCheckForUpdate, 600000
if (!AutoUpdate or DFUpdateRepo = "" or DFUpdBusy or MacroRunning)
	return
DFUpdBusy := true
DFLatestBuild := ""
try
	{
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.SetTimeouts(3000, 3000, 3000, 3000)
	whr.Open("GET", "https://raw.githubusercontent.com/" . DFUpdateRepo . "/HEAD/build.txt?t=" . A_TickCount, false)
	whr.Send()
	if (whr.Status = 200)
		DFLatestBuild := RegExReplace(whr.ResponseText, "[^0-9]", "")
	}
catch e
	DFLatestBuild := ""
if (DFLatestBuild != "" and DFLatestBuild + 0 > DFModBuild + 0 and !MacroRunning)
	gosub, DFInstallUpdate
DFUpdBusy := false
return

DFInstallUpdate:
DFTmp := A_ScriptDir . "\DeepFishUpdate.tmp"
DFBak := A_ScriptFullPath . ".bak"
FileDelete, %DFTmp%
DFGot := false
try
	{
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.SetTimeouts(5000, 5000, 15000, 30000)
	whr.Open("GET", "https://raw.githubusercontent.com/" . DFUpdateRepo . "/HEAD/DeepFish.ahk?t=" . A_TickCount, false)
	whr.Send()
	if (whr.Status = 200)
		{
		ado := ComObjCreate("ADODB.Stream")
		ado.Type := 1
		ado.Open()
		ado.Write(whr.ResponseBody)
		ado.SaveToFile(DFTmp, 2)
		ado.Close()
		DFGot := true
		}
	}
catch e
	DFGot := false
if (!DFGot or !FileExist(DFTmp))
	{
	FileDelete, %DFTmp%
	return
	}
FileGetSize, DFSz, %DFTmp%
FileRead, DFChk, %DFTmp%
DFValid := (DFSz > 200000 and InStr(DFChk, "DFModBuild := " . DFLatestBuild . "`r") and InStr(DFChk, "DFBetaVersion :="))
DFChk := ""
if (!DFValid or MacroRunning)
	{
	FileDelete, %DFTmp%
	return
	}
FileCopy, %A_ScriptFullPath%, %DFBak%, 1
FileCopy, %DFTmp%, %A_ScriptFullPath%, 1
if (ErrorLevel)
	{
	if (FileExist(DFBak))
		FileCopy, %DFBak%, %A_ScriptFullPath%, 1
	FileDelete, %DFTmp%
	return
	}
FileDelete, %DFTmp%
TrayTip, DeepFish, % "Updated to build " . DFLatestBuild . " - restarting.", 3
Sleep, 1500
Reload
return

DFUpdateManual:
return

DFVersionNewer(a, b) {
	StringSplit, aP, a, .
	StringSplit, bP, b, .
	Loop, 4
		{
		av := aP%A_Index%
		bv := bP%A_Index%
		if (av = "")
			av := 0
		if (bv = "")
			bv := 0
		if (av + 0 > bv + 0)
			return true
		if (av + 0 < bv + 0)
			return false
		}
	return false
}

FirstRunGate:

IniRead, FirstRunDone, %SettingsFile%, Meta, FirstRunDone, 0
if (FirstRunDone = 1)
	return

GateMsg := "IMPORTANT DISCLAIMER`n`n"
GateMsg .= "This will Auto-Subscribe you to the channel.`n`n"
GateMsg .= "OK  =  I understand, continue`n"
GateMsg .= "Cancel  =  Exit"

MsgBox, 0x2021, DeepFish BETA — First Time Setup, %GateMsg%
IfMsgBox, Cancel
	ExitApp

Run, https://www.youtube.com/@yatoark?sub_confirmation=1

Sleep, % Tm(3000)

WinGetPos,,, W, H, A

CenterX := W // 2
CenterY := H // 2

Click, %CenterX%, %CenterY%

Sleep, % Tm(100)
Send, {Tab}
Sleep, % Tm(100)
Send, {Tab}
Sleep, % Tm(300)
Send, {Enter}
Sleep, % Tm(500)
Send, {Enter}

IniWrite, 1, %SettingsFile%, Meta, FirstRunDone
FirstRunDone := 1
return

;====================================================================================================;

LoadSettingsFile:

IniRead, ActiveProfile, %SettingsFile%, Profiles, ActiveProfile, Default
IniRead, TotemGlobal, %SettingsFile%, Totem, Global, 0
IniRead, StartStopKey, %SettingsFile%, Hotkeys, StartStop, p
IniRead, ReloadKey, %SettingsFile%, Hotkeys, Reload, o
IniRead, ExitKey, %SettingsFile%, Hotkeys, Exit, m
IniRead, GuiAlwaysOnTop, %SettingsFile%, GUI, AlwaysOnTop, 0
if (GuiAlwaysOnTop != 1)
	GuiAlwaysOnTop := 0
IniRead, GuiKeepOpen, %SettingsFile%, GUI, KeepOpen, 0
if (GuiKeepOpen != 1)
	GuiKeepOpen := 0
IniRead, GuiAutoSave, %SettingsFile%, GUI, AutoSave, 0
if (GuiAutoSave != 1)
	GuiAutoSave := 0
IniRead, ReadThisAccepted, %SettingsFile%, GUI, ReadThisAccepted, 0
if (ReadThisAccepted != 1)
	ReadThisAccepted := 0
hReadThisLockMsg := 0
IniRead, WebhookURL, %SettingsFile%, Webhook, URL, %A_Space%
if (WebhookURL = "ERROR")
	WebhookURL := ""
IniRead, WebhookOn, %SettingsFile%, Webhook, Enabled, 0
IniRead, WebhookShot, %SettingsFile%, Webhook, Screenshot, 0
IniRead, WebhookSummaryMin, %SettingsFile%, Webhook, SummaryMinutes, 10
IniRead, WebhookStallMin, %SettingsFile%, Webhook, StallMinutes, 10
IniRead, WebhookOnCatch, %SettingsFile%, Webhook, OnCatch, 0
IniRead, WebhookOnAlert, %SettingsFile%, Webhook, OnAlert, 0
if (WebhookOn != 1)
	WebhookOn := 0
if (WebhookShot != 1)
	WebhookShot := 0
if (WebhookOnCatch != 1)
	WebhookOnCatch := 0
if (WebhookOnAlert != 1)
	WebhookOnAlert := 0
if (WebhookSummaryMin < 1)
	WebhookSummaryMin := 10
if (WebhookStallMin < 1)
	WebhookStallMin := 10

ActiveProfileFile := ProfilesDir . "\" . ActiveProfile . ".ini"
if !FileExist(ActiveProfileFile)
	{
	ActiveProfile := "Default"
	ActiveProfileFile := DefaultProfileFile
	IniWrite, Default, %SettingsFile%, Profiles, ActiveProfile
	}

return

;====================================================================================================;

LoadActiveProfile:

ConfigWarnings := ""

for i, f in ProfileFields
	{
	sec := f[1]
	key := f[2]
	def := f[3]
	type := f[4]
	SrcFile := (sec = "Aquarium" or sec = "Keeper" or sec = "Update" or sec = "Advanced" or sec = "Misc" or (TotemGlobal and sec = "Totem")) ? SettingsFile : ActiveProfileFile
	IniRead, val, %SrcFile%, %sec%, %key%, %def%
	if (val = "ERROR" and def = "")
		val := ""
	if (val = "" and def != "")
		val := def
	if (!ProfFieldOk(type, val))
		{
		ConfigWarnings .= key . "`n"
		val := def
		IniWrite, %val%, %SrcFile%, %sec%, %key%
		}
	if (type = "bool")
		val := (val = "true") ? true : false
	%key% := val
	}

TotemSelSanitize()
if (ConfigWarnings != "")
	msgbox, 4144, DeepFish - Config Notice, One or more settings in "%ActiveProfile%.ini" were invalid and have been reset to defaults:`n`n%ConfigWarnings%

gosub, AstraMigrateColours
gosub, RefreshControlModes

return

;====================================================================================================;

ProfFieldOk(type, ByRef val) {
	if (type = "bool")
		return (val = "true" or val = "false")
	if (type = "shakemode")
		{
		if (val = "Click")
			val := "Navigation"
		return (val = "Navigation" or val = "Disabled")
		}
	if (type = "specialrod")
		{
		if (val = "Pinion Aria")
			val := "Pinions Aria"
		return (val = "None" or val = "Pinions Aria" or val = "Requiem" or val = "Darkheart" or val = "Bellona's Waraxe" or val = "Dreambreaker" or val = "Tranquility" or val = "Noiseform" or val = "Verdant Oath" or val = "Lullaby" or val = "Castbound" or val = "Remembrance" or val = "MiguRod" or val = "Halibut Harpoon" or val = "Splitbranch Twig" or val = "Astraenus Serenade" or val = "Tryhard Rod" or val = "Chasm Stalker" or val = "Stellarwave Melody")
		}
	if (type = "remembrancemode")
		return (val = "Living" or val = "Departed")
	if (type = "controlmode")
		{
		if (val = "Classic")
			val := "Manual"
		return (val = "Manual" or val = "Precision" or val = "Lines")
		}
	if (type = "castmode")
		return (val = "Normal" or val = "Perfect")
	if (type = "totemsel")
		return (val = "None" or val = "Day" or val = "Night" or val = "Clearcast" or val = "Aurora" or val = "Starfall" or val = "Eclipse" or val = "Tempest" or val = "Windset" or val = "Smokescreen" or val = "Shiny" or val = "Sparkling" or val = "Mutation")
	if (type = "num")
		{
		if val is number
			return true
		return false
		}
	return true
}

MgShareFields() {
	global ProfileFields
	static Cached := ""
	if (IsObject(Cached))
		return Cached
	Cached := []
	for i, f in ProfileFields
		{
		if (f[1] = "Minigame" or f[1] = "Tuning" or f[2] = "FishBarColorTolerance")
			Cached.Push(f)
		}
	return Cached
}

MgShareHash(txt) {
	h := 2166136261
	Loop, Parse, txt
		{
		h := h ^ Asc(A_LoopField)
		h := (h * 16777619) & 0xFFFFFFFF
		}
	return Format("{:04X}", (h ^ (h >> 16)) & 0xFFFF)
}

MgShareSig() {
	sig := ""
	for i, f in MgShareFields()
		sig .= f[2] . ","
	return MgShareHash(sig)
}

BuildDefaultProfile:

for i, f in ProfileFields
	{
	sec := f[1]
	key := f[2]
	val := f[3]
	IniWrite, %val%, %DefaultProfileFile%, %sec%, %key%
	}

return


BuildCastHud:
CastHudIds := []
for idx, spec in [["CkA","F04747"], ["CkB","F04747"], ["CkC","FFD400"], ["CkD","FFD400"], ["CkE","22D3EE"], ["CkF","22D3EE"]]
	{
	nm := spec[1]
	cl := spec[2]
	Gui, %nm%:New, -Caption +AlwaysOnTop +ToolWindow +E0x20 +HwndhMk
	Gui, %nm%:Color, %cl%
	Gui, %nm%:Margin, 0, 0
	Gui, %nm%:Show, NoActivate Hide x0 y0 w22 h7
	CastHudIds.Push(hMk)
	}
CastHudBuilt := true
CH_LastG := -9999
CH_LastT := -9999
CH_LastB := -9999
return

ShowCastHud:
if (!CastHudBuilt)
	gosub, BuildCastHud
CH_LX := WindowLeft + PCGreenL - 28
CH_RX := WindowLeft + PCGreenR + 8
CH_LastG := -9999
CH_LastT := -9999
CH_LastB := -9999
for idx, id in CastHudIds
	DllCall("ShowWindow", "Ptr", id, "Int", 8)
return

HideCastHud:
if (!CastHudBuilt)
	return
for idx, id in CastHudIds
	DllCall("ShowWindow", "Ptr", id, "Int", 0)
return

CastHudMark(gy, wt, wb, gl, gr) {
	global CastHudBuilt, CastHudIds, WindowLeft, WindowTop, CH_LX, CH_RX, CH_LastG, CH_LastT, CH_LastB
	if (!CastHudBuilt)
		return
	lx := WindowLeft + gl - 28
	rx := WindowLeft + gr + 8
	moved := (lx != CH_LX or rx != CH_RX)
	if (moved)
		{
		CH_LX := lx
		CH_RX := rx
		}
	if (gy != CH_LastG or moved)
		{
		CH_LastG := gy
		ay := WindowTop + gy - 3
		DllCall("SetWindowPos", "Ptr", CastHudIds[1], "Ptr", -1, "Int", CH_LX, "Int", ay, "Int", 22, "Int", 7, "UInt", 0x0010)
		DllCall("SetWindowPos", "Ptr", CastHudIds[2], "Ptr", -1, "Int", CH_RX, "Int", ay, "Int", 22, "Int", 7, "UInt", 0x0010)
		}
	if (wt != CH_LastT or moved)
		{
		CH_LastT := wt
		ay := WindowTop + wt - 3
		DllCall("SetWindowPos", "Ptr", CastHudIds[3], "Ptr", -1, "Int", CH_LX, "Int", ay, "Int", 22, "Int", 7, "UInt", 0x0010)
		DllCall("SetWindowPos", "Ptr", CastHudIds[4], "Ptr", -1, "Int", CH_RX, "Int", ay, "Int", 22, "Int", 7, "UInt", 0x0010)
		}
	if (wb != CH_LastB or moved)
		{
		CH_LastB := wb
		ay := WindowTop + wb - 3
		DllCall("SetWindowPos", "Ptr", CastHudIds[5], "Ptr", -1, "Int", CH_LX, "Int", ay, "Int", 22, "Int", 7, "UInt", 0x0010)
		DllCall("SetWindowPos", "Ptr", CastHudIds[6], "Ptr", -1, "Int", CH_RX, "Int", ay, "Int", 22, "Int", 7, "UInt", 0x0010)
		}
}


PerfectCastRelease:

PCGreenRGB := ColMain(PerfectGreenColor)
PCWhiteBGR := ToBGR(ColMain(PerfectWhiteColor))
PCSearchTop := Round(WindowHeight * 0.13)
PCSearchBottom := Round(WindowHeight * 0.90)
PCGreenY := -1
PCGreenL := -1
PCGreenR := -1
PCReachedBottom := false
PCLastFill := -1
PCSpeedSum := 0.0
PCSpeedCount := 0
PCReleased := false
PCLostCount := 0
PCValidFrames := 0
PCFrameDt := 0
PCTipT := 0
PCCycles := 0
PCSawTop := false
PCDir := 0
PCWaitN := PerfectWaitCycles + 0
if (PCWaitN < 0 or PCWaitN > 5)
	PCWaitN := 1

DllCall("QueryPerformanceCounter", "Int64*", PCStart)
PCLastT := PCStart
PCCapT := PCStart

PerfectCastLoop:
if (!MacroRunning)
	{
	tooltip, , , , 8
	gosub, HideCastHud
	return
	}
DllCall("QueryPerformanceCounter", "Int64*", PCNow)
PCElapsed := (PCNow - PCStart) / QpcFreq
if (PCElapsed > PerfectFailTimeout)
	{
	tooltip, Action: Perfect cast timed out - released, %TooltipX%, %Tooltip8%, 8
	gosub, HideCastHud
	return
	}

if (PCGreenY < 0)
	{
	PCVerifyOff := (PCElapsed > 1.5)
	if (!PerfectAcquireGreen())
		{
		tooltip, Action: Looking for cast bar, %TooltipX%, %Tooltip8%, 8
		goto PerfectCastLoop
		}
	PCLostCount := 0
	gosub, ShowCastHud
	}

PCState := PerfectTrackFrame()
if (PCState = 0)
	{
	PCLostCount++
	if (PCLostCount >= 6)
		{
		PCGreenY := -1
		PCLostCount := 0
		}
	goto PerfectCastLoop
	}
PCLostCount := 0
if (PCState = 1)
	{
	tooltip, Action: Perfect cast - bar empty`, waiting, %TooltipX%, %Tooltip8%, 8
	goto PerfectCastLoop
	}

PCTotal := PCWhiteBottom - PCGreenY
if (PCTotal <= 0)
	goto PerfectCastLoop

PCFill := (1 - ((PCWhiteTop - PCGreenY) / PCTotal)) * 100

if (PCFill >= 90)
	PCSawTop := true
if (PCSawTop and PCFill <= 10)
	{
	PCCycles++
	PCSawTop := false
	}

PCOffset := 0.0
if (PCLastFill >= 0)
	{
	PCdt := (PCCapT - PCLastT) / QpcFreq
	if (PCdt > 0.0005)
		{
		PCFrameDt := PCdt
		PCChange := PCFill - PCLastFill
		if (PCChange > 0.5)
			PCDir := 1
		else if (PCChange < -0.5)
			PCDir := -1
		if (PCChange < -50)
			{
			PCSpeedSum := 0.0
			PCSpeedCount := 0
			PCReachedBottom := false
			PCValidFrames := 0
			PCLastFill := -1
			}
		else
			{
			if (PCChange > 0)
				{
				PCSpeedSum += PCChange / PCdt
				PCSpeedCount++
				if (PCSpeedCount > 20)
					{
					PCSpeedSum := PCSpeedSum * 20 / PCSpeedCount
					PCSpeedCount := 20
					}
				}
			if (PCSpeedCount > 0)
				{
				PCAvgSpeed := PCSpeedSum / PCSpeedCount
				PCOffset := 1.5 * Ln(1 + PCAvgSpeed / 25.0)
				if (PerfectReleaseTiming < 0)
					{
					PCBaseMult := 1.0 - (PerfectReleaseTiming / 5.0)
					PCScale := (PCAvgSpeed / 100.0) ** 2
					if (PCScale > 6.0)
						PCScale := 6.0
					PCOffset := PCOffset * (PCBaseMult + (PCBaseMult - 1.0) * PCScale)
					}
				if (PCOffset > 50.0)
					PCOffset := 50.0
				}
			}
		}
	}

PCPredicted := PCFill + PCOffset

if (!PCReachedBottom)
	{
	PCValidFrames++
	if (PCPredicted <= (5.0 + PCOffset) or PCValidFrames >= 3)
		{
		PCReachedBottom := true
		PCLastFill := -1
		PCSpeedSum := 0.0
		PCSpeedCount := 0
		}
	}

if (PerfectReleaseTiming <= 0)
	PCThreshold := 95.5
else
	{
	PCThreshold := 95.5 + (PerfectReleaseTiming / 50.0) * 4.5
	if (PCThreshold > 100)
		PCThreshold := 100
	}

if (PCReachedBottom and PCCycles >= PCWaitN and PCDir > 0 and PCPredicted >= PCThreshold)
	{
	send {lbutton up}
	PCReleased := true
	gosub, HideCastHud
	return
	}

if (PCReachedBottom and PCCycles >= PCWaitN and PCDir > 0 and PCSpeedCount >= 3 and PCAvgSpeed > 1 and PCFrameDt > 0)
	{
	PCLead := ((PCThreshold - PCPredicted) / PCAvgSpeed) + 0.010
	DllCall("QueryPerformanceCounter", "Int64*", PCNowR)
	PCLatency := (PCNowR - PCCapT) / QpcFreq
	if (PCLead < PCFrameDt + PCLatency)
		{
		PCWaitMs := (PCLead - PCLatency) * 1000
		if (PCWaitMs > 250)
			PCWaitMs := 250
		if (PCWaitMs > 0)
			PreciseSleep(PCWaitMs)
		send {lbutton up}
		PCReleased := true
		gosub, HideCastHud
		return
		}
	}

CastHudMark(PCGreenY, Round(PCWhiteTop - (PCOffset / 100.0) * PCTotal), PCWhiteBottom, PCGreenL, PCGreenR)
if ((PCCapT - PCTipT) / QpcFreq >= 0.12)
	{
	PCTipT := PCCapT
	PCFillDbg := Round(PCPredicted)
	PCGateDbg := PCReachedBottom ? "armed" : "arming"
	if (PCCycles < PCWaitN)
		PCGateDbg := "watching swing " . (PCCycles + 1) . "/" . PCWaitN
	tooltip, Action: Perfect %PCFillDbg%`% / %PCThreshold%`% (%PCGateDbg%), %TooltipX%, %Tooltip8%, 8
	}

PCLastFill := PCFill
PCLastT := PCCapT
goto PerfectCastLoop

;====================================================================================================;

CastBarSeen() {
	global PCSearchTop, PCSearchBottom, WindowHeight, PCVerifyOff, PCGreenY, PCGreenL, PCGreenR
	if (WindowHeight < 100)
		return false
	PCSearchTop := Round(WindowHeight * 0.13)
	PCSearchBottom := Round(WindowHeight * 0.90)
	PCVerifyOff := false
	PCGreenY := -1
	return PerfectAcquireGreen()
}

PerfectAcquireGreen() {
	global PCGreenY, PCGreenL, PCGreenR, PerfectGreenColor, PerfectGreenTolerance
	global PCSearchTop, PCSearchBottom, WindowLeft, WindowTop, WindowWidth
	global hPCFullDC, hPCFullBM, pPCFullBits, PCFullW, PCFullH, hPCFullOld
	global PCLastGoodY, PCPrmG, PCPrmGI

	pFn := PcFindPixFn()
	if (!pFn)
		return PerfectAcquireGreenAhk()

	w := WindowWidth
	h := PCSearchBottom - PCSearchTop
	if (w < 8 or h < 8)
		return false

	if (PCFullW != w or PCFullH != h or !hPCFullDC)
		{
		if (hPCFullDC)
			{
			DllCall("SelectObject", "Ptr", hPCFullDC, "Ptr", hPCFullOld)
			DllCall("DeleteObject", "Ptr", hPCFullBM)
			DllCall("DeleteDC", "Ptr", hPCFullDC)
			}
		hSD := DllCall("GetDC", "Ptr", 0, "Ptr")
		hPCFullDC := DllCall("CreateCompatibleDC", "Ptr", hSD, "Ptr")
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt")
		NumPut(w, bi, 4, "Int")
		NumPut(-h, bi, 8, "Int")
		NumPut(1, bi, 12, "UShort")
		NumPut(32, bi, 14, "UShort")
		NumPut(0, bi, 16, "UInt")
		hPCFullBM := DllCall("CreateDIBSection", "Ptr", hPCFullDC, "Ptr", &bi, "UInt", 0, "Ptr*", pPCFullBits, "Ptr", 0, "UInt", 0, "Ptr")
		hPCFullOld := DllCall("SelectObject", "Ptr", hPCFullDC, "Ptr", hPCFullBM, "Ptr")
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD)
		PCFullW := w
		PCFullH := h
		}

	hSD2 := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("BitBlt", "Ptr", hPCFullDC, "Int", 0, "Int", 0, "Int", w, "Int", h
		, "Ptr", hSD2, "Int", WindowLeft, "Int", WindowTop + PCSearchTop, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD2)

	PcSetPrm(PCPrmG, PerfectGreenColor, PerfectGreenTolerance, 1, 0)
	PcSetPrm(PCPrmGI, PerfectGreenColor, PerfectGreenTolerance, 1, 1)

	gRow := -1
	gl := -1
	gr := -1
	Loop, 2
		{
		narrow := (A_Index = 1 and PCLastGoodY >= 0)
		if (narrow)
			{
			y0 := PCLastGoodY - PCSearchTop - 70
			if (y0 < 0)
				y0 := 0
			y1 := PCLastGoodY - PCSearchTop + 70
			if (y1 > h)
				y1 := h
			}
		else
			{
			y0 := 0
			y1 := h
			}
		y := y0
		while (y < y1)
			{
			if (DllCall(pFn, "Ptr", pPCFullBits + y * w * 4, "Int", w, "Int", 4, "Ptr", &PCPrmG, "Int") < 0)
				{
				y++
				continue
				}
			if (!PcRowRun(pPCFullBits + y * w * 4, w, PCPrmG, PCPrmGI, lo, hi))
				{
				y++
				continue
				}
			if ((hi - lo + 1) >= 6 and (hi - lo + 1) < 60 and PcCapVerify(y, lo, hi))
				{
				gRow := y
				gl := lo
				gr := hi
				break
				}
			y++
			while (y < h and PcFind(pPCFullBits + y * w * 4, w, 4, PCPrmG) >= 0)
				y++
			}
		if (gRow >= 0 or !narrow)
			break
		}
	if (gRow < 0)
		return false

	PCGreenY := PCSearchTop + gRow
	PCGreenL := gl
	PCGreenR := gr
	PCLastGoodY := PCGreenY
	return true
}

PerfectTrackFrame() {
	global PCGreenY, PCGreenL, PCGreenR, PCWhiteTop, PCWhiteBottom, PCSearchBottom, PCCapT
	global PerfectGreenColor, PerfectWhiteColor, PerfectGreenTolerance, PerfectWhiteTolerance
	global WindowLeft, WindowTop, WindowWidth
	global hPCColDC, hPCColBM, pPCColBits, PCColW, PCColH, hPCColOld
	global PCPrmG, PCPrmGI, PCPrmW, PCPrmWI

	if (!PcFindPixFn())
		return PerfectTrackFrameAhk()

	w := 160
	mid := Round((PCGreenL + PCGreenR) / 2)
	sx := mid - 80
	if (sx < 0)
		sx := 0
	if (sx + w > WindowWidth)
		sx := WindowWidth - w
	if (sx < 0)
		return 0

	sy := PCGreenY - 50
	if (sy < 0)
		sy := 0
	h := PCSearchBottom - sy
	if (h < 8)
		return 0

	if (PCColW != w or PCColH != h or !hPCColDC)
		{
		if (hPCColDC)
			{
			DllCall("SelectObject", "Ptr", hPCColDC, "Ptr", hPCColOld)
			DllCall("DeleteObject", "Ptr", hPCColBM)
			DllCall("DeleteDC", "Ptr", hPCColDC)
			}
		hSD := DllCall("GetDC", "Ptr", 0, "Ptr")
		hPCColDC := DllCall("CreateCompatibleDC", "Ptr", hSD, "Ptr")
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt")
		NumPut(w, bi, 4, "Int")
		NumPut(-h, bi, 8, "Int")
		NumPut(1, bi, 12, "UShort")
		NumPut(32, bi, 14, "UShort")
		NumPut(0, bi, 16, "UInt")
		hPCColBM := DllCall("CreateDIBSection", "Ptr", hPCColDC, "Ptr", &bi, "UInt", 0, "Ptr*", pPCColBits, "Ptr", 0, "UInt", 0, "Ptr")
		hPCColOld := DllCall("SelectObject", "Ptr", hPCColDC, "Ptr", hPCColBM, "Ptr")
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD)
		PCColW := w
		PCColH := h
		}

	hSD2 := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("QueryPerformanceCounter", "Int64*", PCCapT)
	DllCall("BitBlt", "Ptr", hPCColDC, "Int", 0, "Int", 0, "Int", w, "Int", h
		, "Ptr", hSD2, "Int", WindowLeft + sx, "Int", WindowTop + sy, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD2)

	PcSetPrm(PCPrmG, PerfectGreenColor, PerfectGreenTolerance, 1, 0)
	PcSetPrm(PCPrmGI, PerfectGreenColor, PerfectGreenTolerance, 1, 1)
	PcSetPrm(PCPrmW, PerfectWhiteColor, PerfectWhiteTolerance, 2, 0)
	PcSetPrm(PCPrmWI, PerfectWhiteColor, PerfectWhiteTolerance, 2, 1)

	scanTo := (h < 110) ? h : 110
	gRow := -1
	gl := -1
	gr := -1
	yPrev := PCGreenY - sy
	for i, y in [yPrev, yPrev - 1, yPrev + 1, yPrev - 2, yPrev + 2]
		{
		if (y < 0 or y >= scanTo)
			continue
		if (PcRowRun(pPCColBits + y * w * 4, w, PCPrmG, PCPrmGI, lo, hi) and (hi - lo + 1) >= 6 and (hi - lo + 1) < 60)
			{
			gRow := y
			gl := lo
			gr := hi
			break
			}
		}
	if (gRow < 0)
		{
		y := 0
		while (y < scanTo)
			{
			if (PcRowRun(pPCColBits + y * w * 4, w, PCPrmG, PCPrmGI, lo, hi) and (hi - lo + 1) >= 6 and (hi - lo + 1) < 60)
				{
				gRow := y
				gl := lo
				gr := hi
				break
				}
			y++
			}
		}
	if (gRow < 0)
		return 0

	PCGreenY := sy + gRow
	PCGreenL := sx + gl
	PCGreenR := sx + gr

	cx := (gl + gr) // 2
	x0 := cx - 6
	if (x0 < 0)
		x0 := 0
	x1 := cx + 5
	if (x1 > w - 1)
		x1 := w - 1
	top := -1
	x := x0
	while (x <= x1)
		{
		k := PcFind(pPCColBits + (gRow * w + x) * 4, h - gRow, w * 4, PCPrmW)
		if (k >= 0 and (top < 0 or gRow + k < top))
			top := gRow + k
		x++
		}
	if (top < 0)
		return 1

	bot := top
	x := x0
	while (x <= x1)
		{
		cb := top - 1
		y := top
		Loop
			{
			k := PcFind(pPCColBits + (y * w + x) * 4, (h - y < 17) ? (h - y) : 17, w * 4, PCPrmW)
			if (k < 0 or k > 16)
				break
			y := y + k
			j := PcFind(pPCColBits + ((y + 1) * w + x) * 4, h - y - 1, w * 4, PCPrmWI)
			if (j < 0)
				{
				cb := h - 1
				break
				}
			cb := y + j
			y := cb + 1
			}
		if (cb > bot)
			bot := cb
		x++
		}

	PCWhiteTop := sy + top
	PCWhiteBottom := sy + bot
	return 2
}

; ---- pixel finder -------------------------------------------------------------------------------------

PcSetPrm(ByRef prm, rgbHex, tol, mode, inv) {
	bgr := ToBGR(ColMain(rgbHex))
	VarSetCapacity(prm, 24, 0)
	NumPut((bgr >> 16) & 0xFF, prm, 0, "Int")
	NumPut((bgr >> 8) & 0xFF, prm, 4, "Int")
	NumPut(bgr & 0xFF, prm, 8, "Int")
	NumPut(tol, prm, 12, "Int")
	NumPut(mode, prm, 16, "Int")
	NumPut(inv, prm, 20, "Int")
}

PcFind(p, n, stride, ByRef prm) {
	if (n <= 0)
		return -1
	pFn := PcFindPixFn()
	if (pFn)
		return DllCall(pFn, "Ptr", p, "Int", n, "Int", stride, "Ptr", &prm, "Int")
	return PcFindPixAhk(p, n, stride, NumGet(prm, 0, "Int"), NumGet(prm, 4, "Int"), NumGet(prm, 8, "Int"), NumGet(prm, 12, "Int"), NumGet(prm, 16, "Int"), NumGet(prm, 20, "Int"))
}

PcRowRun(rowP, w, ByRef prm, ByRef prmInv, ByRef lo, ByRef hi) {
	lo := -1
	hi := -1
	x := 0
	while (x < w)
		{
		i := PcFind(rowP + x * 4, w - x, 4, prm)
		if (i < 0)
			break
		rs := x + i
		re := rs
		Loop
			{
			j := PcFind(rowP + (re + 1) * 4, w - re - 1, 4, prmInv)
			if (j < 0)
				{
				re := w - 1
				break
				}
			re := re + j
			k := PcFind(rowP + (re + 1) * 4, (w - re - 1 < 3) ? (w - re - 1) : 3, 4, prm)
			if (k < 0 or k > 2)
				break
			re := re + 1 + k
			}
		if (re - rs + 1 > hi - lo + 1)
			{
			lo := rs
			hi := re
			}
		x := re + 2
		}
	return (lo >= 0)
}

PcCapVerify(gRow, lo, hi) {
	global pPCFullBits, PCFullW, PCFullH, WindowHeight, PCVerifyOff
	if (PCVerifyOff)
		return true
	w := PCFullW
	cx := (lo + hi) // 2
	edge := Round(w * 0.0023)
	if (edge < 4)
		edge := 4
	if (lo - edge < 0 or hi + edge >= w or hi - lo < 3)
		return false
	ok := 0
	tried := 0
	for i, fr in [0.020, 0.040, 0.070, 0.100, 0.145, 0.190]
		{
		y := gRow + Round(WindowHeight * fr)
		if (y >= PCFullH)
			break
		tried++
		p := pPCFullBits + (y * w * 4)
		li := (lo + 2 < cx) ? lo + 2 : cx
		ri := (hi - 2 > cx) ? hi - 2 : cx
		if (!PcBarPx(p, cx) or !PcBarPx(p, li) or !PcBarPx(p, ri))
			continue
		if (Abs(PcLumPx(p, lo + 1) - PcLumPx(p, lo - edge)) < 25)
			continue
		if (Abs(PcLumPx(p, hi - 1) - PcLumPx(p, hi + edge)) < 25)
			continue
		ok++
		}
	if (tried < 3)
		return (ok > 0 and ok = tried)
	return (ok >= 3)
}

PcBarPx(p, x) {
	px := NumGet(p + 0, x * 4, "UInt")
	b := px & 0xFF
	g := (px >> 8) & 0xFF
	r := (px >> 16) & 0xFF
	mx := (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
	mn := (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
	return ((mx < 100 or mn > 150) and (mx - mn) < 45)
}

PcLumPx(p, x) {
	px := NumGet(p + 0, x * 4, "UInt")
	return ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
}

TwigPrompt(ByRef lcx, ByRef rcx, ByRef labY) {
	global WindowLeft, WindowTop, WindowWidth, WindowHeight
	global hTwigDC, hTwigBM, pTwigBits, TwigW, TwigH, hTwigOld
	w := Round(WindowWidth * 0.20)
	h := Round(WindowHeight * 0.41)
	if (w < 60 or h < 60)
		return false
	x0 := Round(WindowWidth * 0.40)
	y0 := Round(WindowHeight * 0.17)
	if (TwigW != w or TwigH != h or !hTwigDC)
		{
		if (hTwigDC)
			{
			DllCall("SelectObject", "Ptr", hTwigDC, "Ptr", hTwigOld)
			DllCall("DeleteObject", "Ptr", hTwigBM)
			DllCall("DeleteDC", "Ptr", hTwigDC)
			}
		hSD := DllCall("GetDC", "Ptr", 0, "Ptr")
		hTwigDC := DllCall("CreateCompatibleDC", "Ptr", hSD, "Ptr")
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt")
		NumPut(w, bi, 4, "Int")
		NumPut(-h, bi, 8, "Int")
		NumPut(1, bi, 12, "UShort")
		NumPut(32, bi, 14, "UShort")
		NumPut(0, bi, 16, "UInt")
		hTwigBM := DllCall("CreateDIBSection", "Ptr", hTwigDC, "Ptr", &bi, "UInt", 0, "Ptr*", pTwigBits, "Ptr", 0, "UInt", 0, "Ptr")
		hTwigOld := DllCall("SelectObject", "Ptr", hTwigDC, "Ptr", hTwigBM, "Ptr")
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD)
		TwigW := w
		TwigH := h
		}
	hSD2 := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("BitBlt", "Ptr", hTwigDC, "Int", 0, "Int", 0, "Int", w, "Int", h
		, "Ptr", hSD2, "Int", WindowLeft + x0, "Int", WindowTop + y0, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD2)

	pbH := Round(h * 0.17)
	white := 0
	y := 0
	while (y < pbH)
		{
		p := pTwigBits + (y * w * 4)
		x := 0
		while (x < w)
			{
			px := NumGet(p + 0, x * 4, "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			mx := (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
			mn := (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
			if (mn > 225 and (mx - mn) < 30)
				white++
			x += 2
			}
		y += 2
		}
	if (white * 4 < (pbH * w) * 0.04)
		return false

	yb := Round(h * 0.878)
	half := w // 2
	lN := 0
	rN := 0
	lSum := 0
	rSum := 0
	ySum := 0
	y := yb
	while (y < h)
		{
		p := pTwigBits + (y * w * 4)
		x := 3
		while (x < w - 3)
			{
			px := NumGet(p + 0, x * 4, "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			mx := (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
			if (mx > 185)
				{
				dark := false
				d := 1
				while (d <= 3)
					{
					q := NumGet(p + 0, (x - d) * 4, "UInt")
					if ((q & 0xFF) < 70 and ((q >> 8) & 0xFF) < 70 and ((q >> 16) & 0xFF) < 70)
						dark := true
					q := NumGet(p + 0, (x + d) * 4, "UInt")
					if ((q & 0xFF) < 70 and ((q >> 8) & 0xFF) < 70 and ((q >> 16) & 0xFF) < 70)
						dark := true
					d++
					}
				if (dark)
					{
					if (x < half)
						{
						lN++
						lSum += x
						}
					else
						{
						rN++
						rSum += x
						}
					ySum += y
					}
				}
			x += 2
			}
		y += 2
		}
	slot := ((h - yb) * half) * 0.035
	if (lN * 4 < slot or rN * 4 < slot)
		return false
	lcx := x0 + Round(lSum / lN)
	rcx := x0 + Round(rSum / rN)
	labY := y0 + Round(ySum / (lN + rN))
	return true
}

PcFindPixAhk(p, n, stride, tB, tG, tR, tol, mode, inv) {
	i := 0
	while (i < n)
		{
		px := NumGet(p + i * stride, 0, "UInt"), b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
		hit := (Abs(b - tB) <= tol and Abs(g - tG) <= tol and Abs(r - tR) <= tol)
		if (!hit and mode = 1 and g > 80 and g - r > 22 and g - b > 22)
			hit := true
		if (!hit and mode = 2 and r > 200 and g > 200 and b > 200)
			{
			mx := r > g ? (r > b ? r : b) : (g > b ? g : b)
			mn := r < g ? (r < b ? r : b) : (g < b ? g : b)
			if (mx - mn < 32)
				hit := true
			}
		if ((hit ? 1 : 0) != inv)
			return i
		i++
		}
	return -1
}

PcFindPixFn() {
	static pFn := "", Hex := "5356575531C04889CE4D63C039D00F8D180100000FB61E0FB66E010FB67E024189DA452B11790341F7DA453B510C0F8F310000004189EA452B5104790341F7DA453B510C0F8F1B0000004189FA452B5108790341F7DA453B510C0F8F05000000E9A2000000458B51104183FA010F852E00000083FD500F8E9B0000004189EA4129FA4183FA160F8E8B0000004189EA4129DA4183FA160F8E7B000000E9660000004183FA020F856C00000081FFC80000000F8E6000000081FDC80000000F8E5400000081FBC80000000F8E480000004189DA4189DB4439D57E034189EA4439DD7D034189EB4439D77E034189FA4439DF7D034189FB4529DA4183FA200F8D15000000E90000000041837914000F841F000000E90B00000041837914000F850F000000FFC04C01C6E9E0FEFFFFB8FFFFFFFF5D5F5E5BC3"
	if (pFn != "")
		return pFn
	pFn := 0
	if (A_PtrSize != 8)
		return 0
	n := StrLen(Hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(Hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	tw := 240
	VarSetCapacity(tBits, tw * 4, 0)
	seed := 4242
	Loop, %tw%
		{
		seed := Mod(seed * 1103515245 + 12345, 2147483648)
		v := (seed >> 8) & 0xFFFFFF
		m := Mod(A_Index, 23)
		if (m = 3)
			v := 0x61AC4A
		else if (m = 9)
			v := 0xF8FCFF
		else if (m = 14)
			v := 0x30C030
		else if (m = 19)
			v := 0xE0FFE0
		NumPut(v, tBits, (A_Index - 1) * 4, "UInt")
		}
	VarSetCapacity(prm, 24, 0)
	same := true
	sawHit := false
	sawMiss := false
	for i, pt in [[0x4A,0xAC,0x61,20,1,0], [0x4A,0xAC,0x61,20,1,1], [0xF3,0xFE,0xFF,25,2,0], [0xF3,0xFE,0xFF,25,2,1], [0x4A,0xAC,0x61,5,0,0], [0x10,0x20,0x30,0,0,0]]
		{
		Loop, 6
			NumPut(pt[A_Index], prm, (A_Index - 1) * 4, "Int")
		for j, S in [[0, 4], [tw - 1, -4], [5, 12]]
			{
			Loop, 8
				{
				st := S[1] + ((S[2] > 0) ? (A_Index - 1) * 5 : -(A_Index - 1) * 5)
				c := (S[2] > 0) ? ((tw - 1 - st) // (S[2] // 4) + 1) : (st + 1)
				a := DllCall(p, "Ptr", &tBits + st * 4, "Int", c, "Int", S[2], "Ptr", &prm, "Int")
				b := PcFindPixAhk(&tBits + st * 4, c, S[2], pt[1], pt[2], pt[3], pt[4], pt[5], pt[6])
				if (a != b)
					same := false
				if (a >= 0)
					sawHit := true
				else
					sawMiss := true
				}
			}
		}
	if (!same or !sawHit or !sawMiss)
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	pFn := p
	return pFn
}

PerfectAcquireGreenAhk() {
	global PCGreenY, PCGreenL, PCGreenR, PerfectGreenColor, PerfectGreenTolerance
	global PerfectWhiteColor, PerfectWhiteTolerance
	global PCSearchTop, PCSearchBottom, WindowLeft, WindowTop, WindowWidth
	global hPCFullDC, hPCFullBM, pPCFullBits, PCFullW, PCFullH, hPCFullOld
	global PCLastGoodY

	w := WindowWidth
	h := PCSearchBottom - PCSearchTop
	if (w < 8 or h < 8)
		return false

	if (PCFullW != w or PCFullH != h or !hPCFullDC)
		{
		if (hPCFullDC)
			{
			DllCall("SelectObject", "Ptr", hPCFullDC, "Ptr", hPCFullOld)
			DllCall("DeleteObject", "Ptr", hPCFullBM)
			DllCall("DeleteDC", "Ptr", hPCFullDC)
			}
		hSD := DllCall("GetDC", "Ptr", 0, "Ptr")
		hPCFullDC := DllCall("CreateCompatibleDC", "Ptr", hSD, "Ptr")
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt")
		NumPut(w, bi, 4, "Int")
		NumPut(-h, bi, 8, "Int")
		NumPut(1, bi, 12, "UShort")
		NumPut(32, bi, 14, "UShort")
		NumPut(0, bi, 16, "UInt")
		hPCFullBM := DllCall("CreateDIBSection", "Ptr", hPCFullDC, "Ptr", &bi, "UInt", 0, "Ptr*", pPCFullBits, "Ptr", 0, "UInt", 0, "Ptr")
		hPCFullOld := DllCall("SelectObject", "Ptr", hPCFullDC, "Ptr", hPCFullBM, "Ptr")
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD)
		PCFullW := w
		PCFullH := h
		}

	hSD2 := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("BitBlt", "Ptr", hPCFullDC, "Int", 0, "Int", 0, "Int", w, "Int", h
		, "Ptr", hSD2, "Int", WindowLeft, "Int", WindowTop + PCSearchTop, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD2)

	bgr := ToBGR(ColMain(PerfectGreenColor))
	tB := (bgr >> 16) & 0xFF
	tG := (bgr >> 8) & 0xFF
	tR := bgr & 0xFF
	tol := PerfectGreenTolerance

	wbgr := ToBGR(ColMain(PerfectWhiteColor))
	wB := (wbgr >> 16) & 0xFF
	wG := (wbgr >> 8) & 0xFF
	wR := wbgr & 0xFF
	wtol := PerfectWhiteTolerance

	gRow := -1
	gl := -1
	gr := -1
	Loop, 2
		{
		narrow := (A_Index = 1 and PCLastGoodY >= 0)
		if (narrow)
			{
			y0 := PCLastGoodY - PCSearchTop - 70
			if (y0 < 0)
				y0 := 0
			y1 := PCLastGoodY - PCSearchTop + 70
			if (y1 > h)
				y1 := h
			}
		else
			{
			y0 := 0
			y1 := h
			}
		y := y0
		while (y < y1 and gRow < 0)
		{
		rowOff := y * w * 4
		lo := -1
		hi := -1
		runStart := -1
		runEnd := -1
		miss := 0
		x := 0
		while (x < w)
			{
			px := NumGet(pPCFullBits + 0, rowOff + (x*4), "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			if ((g > 80 and g > r + 22 and g > b + 22)
				or (Abs(b - tB) <= tol and Abs(g - tG) <= tol and Abs(r - tR) <= tol))
				{
				if (runStart < 0)
					runStart := x
				runEnd := x
				miss := 0
				}
			else if (runStart >= 0)
				{
				miss++
				if (miss > 1)
					{
					if (runEnd - runStart + 1 > hi - lo + 1)
						{
						lo := runStart
						hi := runEnd
						}
					runStart := -1
					miss := 0
					}
				}
			x += 2
			}
		if (runStart >= 0 and runEnd - runStart + 1 > hi - lo + 1)
			{
			lo := runStart
			hi := runEnd
			}
		if (lo >= 0 and (hi - lo + 1) >= 6 and (hi - lo + 1) < 60)
			{
			gRow := y
			gl := lo
			gr := hi
			}
		else if (lo >= 0)
			{
			skip := y
			while (skip < h)
				{
				rOff := skip * w * 4
				any := false
				x2 := 0
				while (x2 < w)
					{
					p2 := NumGet(pPCFullBits + 0, rOff + (x2*4), "UInt")
					b2 := p2 & 0xFF
					g2 := (p2 >> 8) & 0xFF
					r2 := (p2 >> 16) & 0xFF
					if ((g2 > 80 and g2 > r2 + 22 and g2 > b2 + 22)
						or (Abs(b2 - tB) <= tol and Abs(g2 - tG) <= tol and Abs(r2 - tR) <= tol))
						{
						any := true
						break
						}
					x2 += 2
					}
				if (!any)
					break
				skip++
				}
			y := skip
			continue
			}
		y++
		}
		if (gRow >= 0 or !narrow)
			break
		}
	if (gRow < 0)
		return false

	PCGreenY := PCSearchTop + gRow
	PCGreenL := gl
	PCGreenR := gr
	PCLastGoodY := PCGreenY
	return true
}


PerfectTrackFrameAhk() {
	global PCGreenY, PCGreenL, PCGreenR, PCWhiteTop, PCWhiteBottom, PCSearchBottom, PCCapT
	global PerfectGreenColor, PerfectWhiteColor, PerfectGreenTolerance, PerfectWhiteTolerance
	global WindowLeft, WindowTop, WindowWidth
	global hPCColDC, hPCColBM, pPCColBits, PCColW, PCColH, hPCColOld

	w := 160
	mid := Round((PCGreenL + PCGreenR) / 2)
	sx := mid - 80
	if (sx < 0)
		sx := 0
	if (sx + w > WindowWidth)
		sx := WindowWidth - w
	if (sx < 0)
		return 0

	sy := PCGreenY - 50
	if (sy < 0)
		sy := 0
	h := PCSearchBottom - sy
	if (h < 8)
		return 0

	if (PCColW != w or PCColH != h or !hPCColDC)
		{
		if (hPCColDC)
			{
			DllCall("SelectObject", "Ptr", hPCColDC, "Ptr", hPCColOld)
			DllCall("DeleteObject", "Ptr", hPCColBM)
			DllCall("DeleteDC", "Ptr", hPCColDC)
			}
		hSD := DllCall("GetDC", "Ptr", 0, "Ptr")
		hPCColDC := DllCall("CreateCompatibleDC", "Ptr", hSD, "Ptr")
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt")
		NumPut(w, bi, 4, "Int")
		NumPut(-h, bi, 8, "Int")
		NumPut(1, bi, 12, "UShort")
		NumPut(32, bi, 14, "UShort")
		NumPut(0, bi, 16, "UInt")
		hPCColBM := DllCall("CreateDIBSection", "Ptr", hPCColDC, "Ptr", &bi, "UInt", 0, "Ptr*", pPCColBits, "Ptr", 0, "UInt", 0, "Ptr")
		hPCColOld := DllCall("SelectObject", "Ptr", hPCColDC, "Ptr", hPCColBM, "Ptr")
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD)
		PCColW := w
		PCColH := h
		}

	hSD2 := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("QueryPerformanceCounter", "Int64*", PCCapT)
	DllCall("BitBlt", "Ptr", hPCColDC, "Int", 0, "Int", 0, "Int", w, "Int", h
		, "Ptr", hSD2, "Int", WindowLeft + sx, "Int", WindowTop + sy, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD2)

	gbgr := ToBGR(ColMain(PerfectGreenColor))
	gB := (gbgr >> 16) & 0xFF
	gG := (gbgr >> 8) & 0xFF
	gR := gbgr & 0xFF
	gtol := PerfectGreenTolerance

	gRow := -1
	gl := -1
	gr := -1
	scanTo := (h < 110) ? h : 110
	y := 0
	while (y < scanTo and gRow < 0)
		{
		p := pPCColBits + (y * w * 4)
		lo := -1
		hi := -1
		runStart := -1
		runEnd := -1
		miss := 0
		x := 0
		while (x < w)
			{
			px := NumGet(p + 0, 0, "UInt"), bb := px & 0xFF, gg := (px >> 8) & 0xFF, rr := (px >> 16) & 0xFF, p += 4
			if ((gg > 80 and gg > rr + 22 and gg > bb + 22) or (Abs(bb - gB) <= gtol and Abs(gg - gG) <= gtol and Abs(rr - gR) <= gtol))
				runStart := (runStart < 0) ? x : runStart, runEnd := x, miss := 0
			else if (runStart >= 0 and ++miss > 2)
				{
				if (runEnd - runStart + 1 > hi - lo + 1)
					lo := runStart, hi := runEnd
				runStart := -1, miss := 0
				}
			x++
			}
		if (runStart >= 0 and runEnd - runStart + 1 > hi - lo + 1)
			{
			lo := runStart
			hi := runEnd
			}
		if (lo >= 0)
			{
			gRow := y
			gl := lo
			gr := hi
			}
		y++
		}
	if (gRow < 0)
		return 0

	if ((gr - gl + 1) < 6 or (gr - gl + 1) >= 60)
		return 0

	PCGreenY := sy + gRow
	PCGreenL := sx + gl
	PCGreenR := sx + gr

	wbgr := ToBGR(ColMain(PerfectWhiteColor))
	wB := (wbgr >> 16) & 0xFF
	wG := (wbgr >> 8) & 0xFF
	wR := wbgr & 0xFF
	wtol := PerfectWhiteTolerance

	top := -1
	bot := -1
	y := gRow
	while (y < h and (top < 0 or y - bot <= 16))
		{
		p := pPCColBits + ((y * w + 74) * 4)
		pe := p + 48
		while (p < pe)
			{
			px := NumGet(p + 0, 0, "UInt"), bb := px & 0xFF, gg := (px >> 8) & 0xFF, rr := (px >> 16) & 0xFF, p += 4
			if ((rr > 200 and gg > 200 and bb > 200 and ((rr > gg) ? ((rr > bb) ? rr : bb) : ((gg > bb) ? gg : bb)) - ((rr < gg) ? ((rr < bb) ? rr : bb) : ((gg < bb) ? gg : bb)) < 32) or (Abs(bb - wB) <= wtol and Abs(gg - wG) <= wtol and Abs(rr - wR) <= wtol))
				{
				if (top < 0)
					top := y
				bot := y
				break
				}
			}
		y++
		}

	if (top < 0)
		return 1
	PCWhiteTop := sy + top
	PCWhiteBottom := sy + bot
	return 2
}

;====================================================================================================;


SetupCapture:

if (hCaptureMemDC)
	{
	DllCall("SelectObject", "Ptr", hCaptureMemDC, "Ptr", hCaptureOldBitmap)
	DllCall("DeleteObject", "Ptr", hCaptureBitmap)
	DllCall("DeleteDC", "Ptr", hCaptureMemDC)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hCaptureScreenDC)
	}

CaptureW := Round(FishBarRight - FishBarLeft)
if (CaptureW < 1)
	CaptureW := 1
CaptureH := Round(FishBarBottom - FishBarTop) + 1
CapExtra := (SpecialRod = "Pinions Aria") ? Round(WindowHeight * 0.035) : 0
PnProgRow := Round(WindowHeight * 0.9111) - Round(FishBarTop)
if (!CapExtra or PnProgRow < 4 or PnProgRow + 4 >= CaptureH + 20 + CapExtra)
	PnProgRow := -1
PcSetPrm(PnPrmW, "0xDEE4FA", 28, 2, 0)
PcSetPrm(PnPrmWI, "0xDEE4FA", 28, 2, 1)
PcSetPrm(PnPrmP, "0x998FE4", 30, 0, 0)
PcSetPrm(PnPrmPI, "0x998FE4", 30, 0, 1)
if (CaptureH < 1)
	CaptureH := 1

hCaptureScreenDC := DllCall("GetDC", "Ptr", 0, "Ptr")
hCaptureMemDC := DllCall("CreateCompatibleDC", "Ptr", hCaptureScreenDC, "Ptr")

VarSetCapacity(CaptureBMI, 40, 0)
NumPut(40, CaptureBMI, 0, "UInt")
NumPut(CaptureW, CaptureBMI, 4, "Int")
NumPut(-(CaptureH + 38 + CapExtra), CaptureBMI, 8, "Int")
NumPut(1, CaptureBMI, 12, "UShort")
NumPut(32, CaptureBMI, 14, "UShort")
NumPut(0, CaptureBMI, 16, "UInt")

hCaptureBitmap := DllCall("CreateDIBSection", "Ptr", hCaptureScreenDC, "Ptr", &CaptureBMI, "UInt", 0, "Ptr*", pCaptureBits, "Ptr", 0, "UInt", 0, "Ptr")
hCaptureOldBitmap := DllCall("SelectObject", "Ptr", hCaptureMemDC, "Ptr", hCaptureBitmap, "Ptr")
pUiEdgeOwn := pCaptureBits
pCaptureOwn := pCaptureBits + (18 * CaptureW * 4)
pCaptureBits := pCaptureOwn

UiTopRows := 29
UiBotRows := 33
UiBotOff := CaptureH + 5
UiEdgeH := CaptureH + 38
UiEdgeOn := true
UiTopStart := 18 - Round(WindowHeight * 0.0095)
if (UiTopStart < 2)
	UiTopStart := 2
UiGateN := 0
UiLatchMs := (SpecialRod = "Pinions Aria" or SpecialRod = "Darkheart") ? 500 : 130
UiResumeF := (SpecialRod = "Pinions Aria" or SpecialRod = "Darkheart") ? 0 : 0.75
if (hUiGrnDC)
	{
	DllCall("SelectObject", "Ptr", hUiGrnDC, "Ptr", hUiGrnOld)
	DllCall("DeleteObject", "Ptr", hUiGrnBM)
	DllCall("DeleteDC", "Ptr", hUiGrnDC)
	}
UiGrnW := Round(WindowWidth * 0.045)
UiGrnH := Round(WindowHeight * 0.10)
if (UiGrnW < 8)
	UiGrnW := 8
if (UiGrnH < 8)
	UiGrnH := 8
hUiGrnDC := DllCall("CreateCompatibleDC", "Ptr", hCaptureScreenDC, "Ptr")
VarSetCapacity(UiGrnBMI, 40, 0)
NumPut(40, UiGrnBMI, 0, "UInt")
NumPut(UiGrnW, UiGrnBMI, 4, "Int")
NumPut(-UiGrnH, UiGrnBMI, 8, "Int")
NumPut(1, UiGrnBMI, 12, "UShort")
NumPut(32, UiGrnBMI, 14, "UShort")
hUiGrnBM := DllCall("CreateDIBSection", "Ptr", hCaptureScreenDC, "Ptr", &UiGrnBMI, "UInt", 0, "Ptr*", pUiGrnBits, "Ptr", 0, "UInt", 0, "Ptr")
hUiGrnOld := DllCall("SelectObject", "Ptr", hUiGrnDC, "Ptr", hUiGrnBM, "Ptr")
UiState := 0
UiEdgesKnownGood := false

if (hNoteMemDC)
	{
	DllCall("SelectObject", "Ptr", hNoteMemDC, "Ptr", hNoteOldBitmap)
	DllCall("DeleteObject", "Ptr", hNoteBitmap)
	DllCall("DeleteDC", "Ptr", hNoteMemDC)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hNoteScreenDC)
	}

NoteW := CaptureW
NoteH := Round(NoteRegionHeight)
if (SpecialRod = "Tranquility" and NoteH < Round(WindowHeight * 0.55))
	NoteH := Round(WindowHeight * 0.55)
if (SpecialRod = "Noiseform" and NoteH < Round(WindowHeight * 0.50))
	NoteH := Round(WindowHeight * 0.50)
if (SpecialRod = "Halibut Harpoon")
	NoteH := Round(WindowHeight * 0.075)
if (NoteH < 20)
	NoteH := 20
if (NoteH > 1400)
	NoteH := 1400
NoteTop := Round(FishBarTop) - NoteH
if (NoteTop < 0)
	{
	NoteTop := 0
	NoteH := Round(FishBarTop)
	if (NoteH < 20)
		NoteH := 20
	}
if (SpecialRod = "Noiseform")
	{
	nfTop := Round(WindowHeight * 0.5194) - Round(WindowHeight * 0.135) - 2
	if (nfTop > NoteTop and nfTop < Round(FishBarTop) - 80)
		{
		NoteTop := nfTop
		NoteH := Round(FishBarTop) - NoteTop
		}
	}

NoteIndep := false
NoteNeeded := (SpecialRod = "Pinions Aria" or SpecialRod = "Noiseform"
	or SpecialRod = "Tranquility" or SpecialRod = "Lullaby" or SpecialRod = "Halibut Harpoon"
	or SpecialRod = "Stellarwave Melody")
NoteOriginX := Round(FishBarLeft)
NoteOriginY := NoteTop
if (SpecialRod = "Pinions Aria")
	{
	nrx := Round(ClickShakeLeft)
	nrw := Round(ClickShakeRight - ClickShakeLeft)
	nry := Round(ClickShakeTop)
	nrh := Round(ClickShakeBottom - ClickShakeTop)
	if (nry + nrh > Round(FishBarTop))
		nrh := Round(FishBarTop) - nry
	if (nrw >= 20 and nrh >= 40)
		{
		NoteIndep := true
		NoteOriginX := nrx
		NoteOriginY := nry
		NoteW := nrw
		NoteH := nrh
		}
	}
if (SpecialRod = "Stellarwave Melody")
	{
	NoteIndep := true
	NoteOriginX := Round(WindowWidth * 0.20)
	NoteOriginY := Round(WindowHeight * 0.69)
	NoteW := Round(WindowWidth * 0.60)
	NoteH := Round(WindowHeight * 0.10)
	if (NoteH < 20)
		NoteH := 20
	}

hNoteScreenDC := DllCall("GetDC", "Ptr", 0, "Ptr")
hNoteMemDC := DllCall("CreateCompatibleDC", "Ptr", hNoteScreenDC, "Ptr")

VarSetCapacity(NoteBMI, 40, 0)
NumPut(40, NoteBMI, 0, "UInt")
NoteFullH := NoteIndep ? NoteH : (NoteH + CaptureH + 20)
if (!NoteIndep)
	NoteFullH := NoteFullH + CapExtra
if (SpecialRod = "Stellarwave Melody" and NoteIndep and Round(FishBarTop) - 18 >= NoteOriginY and Round(FishBarLeft) >= NoteOriginX and Round(FishBarLeft) - NoteOriginX + CaptureW <= NoteW)
	NoteFullH := Max(NoteH, Round(FishBarTop) - 18 + CaptureH + 38 + CapExtra - NoteOriginY)
NumPut(NoteW, NoteBMI, 4, "Int")
NumPut(-NoteFullH, NoteBMI, 8, "Int")
NumPut(1, NoteBMI, 12, "UShort")
NumPut(32, NoteBMI, 14, "UShort")
NumPut(0, NoteBMI, 16, "UInt")

hNoteBitmap := DllCall("CreateDIBSection", "Ptr", hNoteScreenDC, "Ptr", &NoteBMI, "UInt", 0, "Ptr*", pNoteBits, "Ptr", 0, "UInt", 0, "Ptr")
hNoteOldBitmap := DllCall("SelectObject", "Ptr", hNoteMemDC, "Ptr", hNoteBitmap, "Ptr")

return

;====================================================================================================;

CaptureFishBar:
CaptureStrip()
CaptureEdgeStrips()
LineScanned := false
NoiseScanned := false
CastScanned := false
RemScanned := false
RemBarScanned := false
MiguScanned := false
MiguBarScanned := false
HaliBarScanned := false
TryScanned := false
SwScanned := false
return

;====================================================================================================;

BuildHud:
gosub, HudDestroySurface
if (HudBuilt)
	Gui, Hud:Destroy
HudW := Round(TrackRight - TrackLeft)
if (HudW < 40)
	HudW := 40
HudH := 34
Gui, Hud:New, +AlwaysOnTop -Caption +ToolWindow +E0x80020 +HwndhHudGui
Gui, Hud:Color, 010101
Gui, Hud:Margin, 0, 0
Gui, Hud:Show, NoActivate Hide, DeepFishHud
HudBuilt := true
HudGpOk := HudSurfaceMake(HudW, HudH)
HudFishTgt := -1
HudBarTgt := -1
HudFishCur := -1
HudBarCur := -1
HudNoteX := -1
HudNote2X := -1
HudFish2Tgt := -1
HudFish2Cur := -1
HudBar2Tgt := -1
HudBar2Cur := -1
HudBar2W := 0
HudZoneShown := false
BarWTrust := 0
HudWRing := []
HudWMed := 0
HudDirty := true
HudLastKey := ""
HudPrevT := 0
return

;====================================================================================================;
;====================================================================================================;

HudGdipStart() {
	global HudGdipToken
	if (HudGdipToken)
		return true
	if (!DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr"))
		{
		if (!DllCall("LoadLibrary", "Str", "gdiplus", "Ptr"))
			return false
		}
	VarSetCapacity(gsi, A_PtrSize = 8 ? 24 : 16, 0)
	NumPut(1, gsi, 0, "UInt")
	if (DllCall("gdiplus\GdiplusStartup", "Ptr*", gtk, "Ptr", &gsi, "Ptr", 0, "UInt") != 0)
		return false
	HudGdipToken := gtk
	return true
}

HudSurfaceMake(w, h) {
	global hHudDC, hHudBM, hHudOldBM, pHudBits, pHudGfx, pHudBmp, HudSurfW, HudSurfH
	gosub, HudDestroySurface
	if (!HudGdipStart())
		return false
	hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
	hHudDC := DllCall("CreateCompatibleDC", "Ptr", hdcS, "Ptr")
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
	if (!hHudDC)
		return false
	VarSetCapacity(hbi, 40, 0)
	NumPut(40, hbi, 0, "UInt")
	NumPut(w, hbi, 4, "Int")
	NumPut(-h, hbi, 8, "Int")
	NumPut(1, hbi, 12, "UShort")
	NumPut(32, hbi, 14, "UShort")
	NumPut(0, hbi, 16, "UInt")
	hHudBM := DllCall("CreateDIBSection", "Ptr", hHudDC, "Ptr", &hbi, "UInt", 0, "Ptr*", pHudBits, "Ptr", 0, "UInt", 0, "Ptr")
	if (!hHudBM)
		return false
	hHudOldBM := DllCall("SelectObject", "Ptr", hHudDC, "Ptr", hHudBM, "Ptr")

	if (DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", w*4
		, "Int", 0xE200B, "Ptr", pHudBits, "Ptr*", pbm) != 0)
		return false
	pHudBmp := pbm
	if (DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pHudBmp, "Ptr*", pg) != 0)
		return false
	pHudGfx := pg
	DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pHudGfx, "Int", 4)
	DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pHudGfx, "Int", 2)
	HudSurfW := w
	HudSurfH := h
	return true
}

HudWPush(w) {
	global HudWRing, HudWMed
	if (w <= 0)
		return
	if (!IsObject(HudWRing))
		HudWRing := []
	HudWRing.Push(w)
	if (HudWRing.MaxIndex() > 5)
		HudWRing.RemoveAt(1)
	n := HudWRing.MaxIndex()
	srt := []
	Loop, %n%
		srt.Push(HudWRing[A_Index])
	i := 2
	while (i <= n)
		{
		v := srt[i]
		j := i - 1
		while (j >= 1 and srt[j] > v)
			{
			srt[j+1] := srt[j]
			j--
			}
		srt[j+1] := v
		i++
		}
	HudWMed := srt[(n // 2) + 1]
}

HudBarW() {
	global BarWTrust, WhiteBarSize, RunWidth, HudWMed, HudWRing
	if (HudWMed > 8 and IsObject(HudWRing) and HudWRing.MaxIndex() >= 3)
		return HudWMed
	if (WhiteBarSize > 8)
		return WhiteBarSize
	if (BarWTrust > 8)
		return BarWTrust
	return (RunWidth > 8) ? RunWidth : 8
}

HudRoundRect(x, y, w, h, r, argb) {
	global pHudGfx
	if (w <= 0 or h <= 0)
		return
	if (r*2 > h)
		r := h/2
	if (r*2 > w)
		r := w/2
	if (r < 0.5)
		r := 0.5
	d := r*2
	DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pth)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180, "Float", 90)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x+w-d, "Float", y, "Float", d, "Float", d, "Float", 270, "Float", 90)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x+w-d, "Float", y+h-d, "Float", d, "Float", d, "Float", 0, "Float", 90)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x, "Float", y+h-d, "Float", d, "Float", d, "Float", 90, "Float", 90)
	DllCall("gdiplus\GdipClosePathFigure", "Ptr", pth)
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", br)
	DllCall("gdiplus\GdipFillPath", "Ptr", pHudGfx, "Ptr", br, "Ptr", pth)
	DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
	DllCall("gdiplus\GdipDeletePath", "Ptr", pth)
}

HudRoundOutline(x, y, w, h, r, argb, thick) {
	global pHudGfx
	if (w <= 0 or h <= 0)
		return
	if (r*2 > h)
		r := h/2
	if (r*2 > w)
		r := w/2
	if (r < 0.5)
		r := 0.5
	d := r*2
	DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pth)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180, "Float", 90)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x+w-d, "Float", y, "Float", d, "Float", d, "Float", 270, "Float", 90)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x+w-d, "Float", y+h-d, "Float", d, "Float", d, "Float", 0, "Float", 90)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", pth, "Float", x, "Float", y+h-d, "Float", d, "Float", d, "Float", 90, "Float", 90)
	DllCall("gdiplus\GdipClosePathFigure", "Ptr", pth)
	DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", thick, "Int", 2, "Ptr*", pen)
	DllCall("gdiplus\GdipDrawPath", "Ptr", pHudGfx, "Ptr", pen, "Ptr", pth)
	DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
	DllCall("gdiplus\GdipDeletePath", "Ptr", pth)
}

HudEllipse(cx, cy, rx, ry, argb) {
	global pHudGfx
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", br)
	DllCall("gdiplus\GdipFillEllipse", "Ptr", pHudGfx, "Ptr", br, "Float", cx-rx, "Float", cy-ry, "Float", rx*2, "Float", ry*2)
	DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
}

HudRender() {
	global pHudGfx, pHudBmp, hHudDC, hHudGui, HudSurfW, HudSurfH, HudGpOk, HudBuilt
	global HudFishCur, HudBarCur, HudNoteX, HudNote2X, HudZoneShown, HudFish2Cur, HudBar2Cur, HudBar2W, TrackLeft, TrackRight
	global FishBarLeft, FishBarRight, MaxLeftBar, MaxRightBar, RunWidth, WhiteBarSize
	bx := -1
	bw := -1
	if (!HudBuilt or !HudGpOk or !pHudGfx)
		return
	W := HudSurfW
	H := HudSurfH

	DllCall("gdiplus\GdipSetCompositingMode", "Ptr", pHudGfx, "Int", 1)
	DllCall("gdiplus\GdipGraphicsClear", "Ptr", pHudGfx, "UInt", 0x00000000)
	DllCall("gdiplus\GdipSetCompositingMode", "Ptr", pHudGfx, "Int", 0)

	trY := 9
	trH := 16
	trR := trH / 2

	; --- track ---------------------------------------------------------------------------------
	HudRoundRect(0, trY, W, trH, trR, 0xDC0A0D13)
	HudRoundOutline(0.75, trY + 0.75, W - 1.5, trH - 1.5, trR, 0x8C3A465A, 1.5)

	; --- edge zones the macro will not chase into ----------------------------------------------
	if (HudZoneShown)
		{
		zl := Round(MaxLeftBar - TrackLeft)
		zr := Round(MaxRightBar - TrackLeft)
		if (zl > 2)
			{
			HudRoundRect(0, trY, zl, trH, trR, 0x4DF59E0B)
			HudRoundRect(zl - 1.25, trY - 2, 2.5, trH + 4, 1.25, 0xE6FBB63C)
			}
		if (zr < W - 2)
			{
			HudRoundRect(zr, trY, W - zr, trH, trR, 0x4DF59E0B)
			HudRoundRect(zr - 1.25, trY - 2, 2.5, trH + 4, 1.25, 0xE6FBB63C)
			}
		}

	; --- the reeling bar, at its true width -----------------------------------------------------
	if (HudBarCur >= 0)
		{
		bw := HudBarW()
		if (bw > W)
			bw := W
		bx := Round(HudBarCur - TrackLeft - (bw / 2))
		if (bx < 0)
			bx := 0
		if (bx + bw > W)
			bx := W - bw
		HudRoundRect(bx, trY - 3, bw, trH + 6, (trH + 6) / 2, 0x4C5EA6FF)
		HudRoundOutline(bx + 1, trY - 2, bw - 2, trH + 4, (trH + 4) / 2, 0xE64EA1F7, 1.6)
		HudRoundRect(bx + (bw / 2) - 0.5, trY + 1, 1, trH - 2, 0.5, 0x805EA6FF)
		}
	if (HudBar2Cur >= 0 and HudBar2W > 0)
		{
		bw2 := HudBar2W
		if (bw2 > W)
			bw2 := W
		bx2 := Round(HudBar2Cur - TrackLeft - (bw2 / 2))
		if (bx2 < 0)
			bx2 := 0
		if (bx2 + bw2 > W)
			bx2 := W - bw2
		HudRoundRect(bx2, trY - 3, bw2, trH + 6, (trH + 6) / 2, 0x4C5EA6FF)
		HudRoundOutline(bx2 + 1, trY - 2, bw2 - 2, trH + 4, (trH + 4) / 2, 0xE64EA1F7, 1.6)
		HudRoundRect(bx2 + (bw2 / 2) - 0.5, trY + 1, 1, trH - 2, 0.5, 0x805EA6FF)
		}

	; --- notes ----------------------------------------------------------------------------------
	if (HudNote2X >= 0)
		{
		nx := Min(Max(Round(HudNote2X - TrackLeft), 0), W)
		HudRoundRect(nx - 1.5, trY + 1, 3, trH - 2, 1.5, 0xCC8C1856)
		}
	if (HudNoteX >= 0)
		{
		nx := Min(Max(Round(HudNoteX - TrackLeft), 0), W)
		HudRoundRect(nx - 2, trY - 1, 4, trH + 2, 2, 0xF2FF2D9B)
		}

	; --- the fish --------------------------------------------------------------------------------
	if (HudFishCur >= 0)
		{
		fx := Min(Max(HudFishCur - TrackLeft, 0), W)
		cy := trY + (trH / 2)
		HudEllipse(fx, cy, 11, 11, 0x2622C55E)
		HudEllipse(fx, cy, 6.5, 6.5, 0x4D22C55E)
		HudRoundRect(fx - 1.5, trY - 5, 3, trH + 10, 1.5, 0xE622C55E)
		HudEllipse(fx, cy, 3.6, 3.6, 0xFF34D96F)
		HudEllipse(fx - 1, cy - 1.2, 1.2, 1.2, 0xB3FFFFFF)
		}
	if (HudFish2Cur >= 0)
		{
		fx := Min(Max(HudFish2Cur - TrackLeft, 0), W)
		cy := trY + (trH / 2)
		HudEllipse(fx, cy, 11, 11, 0x2622C55E)
		HudEllipse(fx, cy, 6.5, 6.5, 0x4D22C55E)
		HudRoundRect(fx - 1.5, trY - 5, 3, trH + 10, 1.5, 0xE622C55E)
		HudEllipse(fx, cy, 3.6, 3.6, 0xFF34D96F)
		HudEllipse(fx - 1, cy - 1.2, 1.2, 1.2, 0xB3FFFFFF)
		}

	; --- push to screen ---------------------------------------------------------------------------
	DllCall("gdiplus\GdipFlush", "Ptr", pHudGfx, "Int", 0)
	VarSetCapacity(hsz, 8, 0)
	NumPut(W, hsz, 0, "Int")
	NumPut(H, hsz, 4, "Int")
	VarSetCapacity(hpt, 8, 0)
	VarSetCapacity(hbf, 4, 0)
	NumPut(0, hbf, 0, "UChar")
	NumPut(0, hbf, 1, "UChar")
	NumPut(255, hbf, 2, "UChar")
	NumPut(1, hbf, 3, "UChar")
	DllCall("UpdateLayeredWindow", "Ptr", hHudGui, "Ptr", 0, "Ptr", 0, "Ptr", &hsz
		, "Ptr", hHudDC, "Ptr", &hpt, "UInt", 0, "Ptr", &hbf, "UInt", 2)
}

HudDestroySurface:
if (pHudGfx)
	{
	DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pHudGfx)
	pHudGfx := 0
	}
if (pHudBmp)
	{
	DllCall("gdiplus\GdipDisposeImage", "Ptr", pHudBmp)
	pHudBmp := 0
	}
if (hHudDC)
	{
	if (hHudOldBM)
		DllCall("SelectObject", "Ptr", hHudDC, "Ptr", hHudOldBM)
	DllCall("DeleteDC", "Ptr", hHudDC)
	hHudDC := 0
	hHudOldBM := 0
	}
if (hHudBM)
	{
	DllCall("DeleteObject", "Ptr", hHudBM)
	hHudBM := 0
	}
pHudBits := 0
return

;====================================================================================================;

ShowHud:
if (OverlayHidden)
	{
	gosub, HideHud
	return
	}
if (!HudBuilt)
	gosub, BuildHud
HudNeedW := Round(TrackRight - TrackLeft)
if (HudNeedW < 40)
	HudNeedW := 40
if (HudNeedW != HudSurfW or !HudGpOk)
	{
	HudW := HudNeedW
	HudGpOk := HudSurfaceMake(HudW, HudH)
	}
RobloxClientRect(RobloxHwnd, HudRX, HudRY)
HudX := HudRX + Round(TrackLeft)
HudY := HudRY + Round(FishBarTooltipHeight) - 11
Gui, Hud:Show, x%HudX% y%HudY% w%HudW% h%HudH% NoActivate
HudDirty := true
HudLastKey := ""
HudPrevT := 0
HudRenderAvg := 0
HudTickMs := 16
HudTickN := 0
settimer, HudSmooth, 16
return


HideHud:
settimer, HudSmooth, off
if (HudBuilt)
	Gui, Hud:Cancel
return

;====================================================================================================;

HudSmooth:
if (!HudBuilt or !HudGpOk)
	return
DllCall("QueryPerformanceCounter", "Int64*", HudNowT)
HudDt := HudPrevT ? ((HudNowT - HudPrevT) / QpcFreq) : 0.008
HudPrevT := HudNowT
if (HudDt > 0.1)
	HudDt := 0.1
HudEase := 1 - Exp(-HudDt / 0.030)
if (HudFishTgt >= 0)
	{
	if (HudFishCur < 0)
		HudFishCur := HudFishTgt
	else
		HudFishCur := HudFishCur + ((HudFishTgt - HudFishCur) * HudEase)
	}
if (HudBarTgt >= 0)
	{
	if (HudBarCur < 0)
		HudBarCur := HudBarTgt
	else
		HudBarCur := HudBarCur + ((HudBarTgt - HudBarCur) * HudEase)
	}
if (HudFish2Tgt >= 0)
	{
	if (HudFish2Cur < 0)
		HudFish2Cur := HudFish2Tgt
	else
		HudFish2Cur := HudFish2Cur + ((HudFish2Tgt - HudFish2Cur) * HudEase)
	}
if (HudBar2Tgt >= 0)
	{
	if (HudBar2Cur < 0)
		HudBar2Cur := HudBar2Tgt
	else
		HudBar2Cur := HudBar2Cur + ((HudBar2Tgt - HudBar2Cur) * HudEase)
	}
HudKey := Round(HudFishCur) . "|" . Round(HudBarCur) . "|" . Round(HudNoteX) . "|" . Round(HudNote2X)
	. "|" . Round(RunWidth) . "|" . (HudZoneShown ? Round(MaxLeftBar) . "," . Round(MaxRightBar) : "-")
	. "|" . Round(HudFish2Cur) . "|" . Round(HudBar2Cur) . "|" . Round(HudBar2W)
if (!HudDirty and HudKey = HudLastKey)
	return
HudLastKey := HudKey
HudDirty := false
DllCall("QueryPerformanceCounter", "Int64*", HudR0)
HudRender()
DllCall("QueryPerformanceCounter", "Int64*", HudR1)
HudRenderMs := (HudR1 - HudR0) * 1000.0 / QpcFreq
HudRenderAvg := (HudRenderAvg > 0) ? ((HudRenderAvg * 0.9) + (HudRenderMs * 0.1)) : HudRenderMs
HudTickN := HudTickN + 1
if (Mod(HudTickN, 30) = 0)
	{
	HudWant := (HudRenderAvg > 4.0) ? 50 : ((HudRenderAvg > 2.0) ? 33 : 16)
	if (HudWant != HudTickMs)
		{
		HudTickMs := HudWant
		settimer, HudSmooth, %HudTickMs%
		}
	}
return

MoveHudFish(wx) {
	global HudBuilt, HudFishTgt, HudFishCur
	if (!HudBuilt or wx < 0)
		return
	HudFishTgt := wx
	if (HudFishCur < 0 or Abs(wx - HudFishCur) > 150)
		HudFishCur := wx
}

MoveHudFish2(wx) {
	global HudBuilt, HudFish2Tgt, HudFish2Cur
	if (!HudBuilt or wx < 0)
		return
	HudFish2Tgt := wx
	if (HudFish2Cur < 0 or Abs(wx - HudFish2Cur) > 150)
		HudFish2Cur := wx
}

MoveHudBar2Span(l, w) {
	global HudBuilt, HudBar2Tgt, HudBar2Cur, HudBar2W
	if (!HudBuilt or l < 0 or w <= 0)
		return
	HudBar2W := w
	HudBar2Tgt := l + (w / 2)
	if (HudBar2Cur < 0)
		HudBar2Cur := HudBar2Tgt
}

MoveHudNote(wx) {
	global HudBuilt, HudNoteX, HudDirty
	if (!HudBuilt)
		return
	nv := (wx < 0) ? -1 : wx
	if (nv >= 0 and HudNoteX >= 0 and Abs(nv - HudNoteX) < 2)
		return
	HudNoteX := nv
	HudDirty := true
}

MoveHudNote2(wx) {
	global HudBuilt, HudNote2X, HudDirty
	if (!HudBuilt)
		return
	nv := (wx < 0) ? -1 : wx
	if (nv >= 0 and HudNote2X >= 0 and Abs(nv - HudNote2X) < 2)
		return
	HudNote2X := nv
	HudDirty := true
}

MoveHudBarSpan(l, w) {
	global WhiteBarSize, FishX, HudWMed
	if (l < 0 or w <= 0)
		return
	HudWPush(w)
	if (HudWMed > 0 and Abs(w - HudWMed) > (HudWMed * 0.6))
		return
	MoveHudBarC(l + (w / 2))
}

MoveHudBarC(wx) {
	global HudBuilt, HudBarTgt, HudBarCur, FishBarLeft, FishBarRight, RunWidth, WhiteBarSize, TrackLeft, TrackRight
	if (!HudBuilt or wx < 0)
		return
	bw := HudBarW()
	lo := TrackLeft + (bw / 2)
	hi := TrackRight - (bw / 2)
	if (hi < lo)
		hi := lo
	if (wx < lo)
		wx := lo
	else if (wx > hi)
		wx := hi
	if (HudBarCur >= 0)
		{
		maxStep := (TrackRight - TrackLeft) * 0.15
		if (maxStep > 8)
			{
			if (wx > HudBarCur + maxStep)
				wx := HudBarCur + maxStep
			else if (wx < HudBarCur - maxStep)
				wx := HudBarCur - maxStep
			}
		}
	HudBarTgt := wx
	if (HudBarCur < 0)
		HudBarCur := wx
}

UpdateHud:
if (!HudBuilt)
	return
HudDirty := true
return

RobloxClientRect(hwnd, ByRef rcx, ByRef rcy, ByRef rcw := "", ByRef rch := "") {
	VarSetCapacity(rcr, 16, 0)
	VarSetCapacity(rcp, 8, 0)
	if (!hwnd or !DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rcr) or !DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &rcp))
		{
		WinGetPos, rcx, rcy, rcw, rch, ahk_id %hwnd%
		return false
		}
	rcx := NumGet(rcp, 0, "Int")
	rcy := NumGet(rcp, 4, "Int")
	rcw := NumGet(rcr, 8, "Int")
	rch := NumGet(rcr, 12, "Int")
	return true
}

CaptureNoteRegion() {
	global hNoteMemDC, hNoteScreenDC, NoteW, NoteFullH, NoteOriginX, NoteOriginY, RobloxHwnd
	if (!hNoteMemDC)
		return
	RobloxClientRect(RobloxHwnd, nwx, nwy)
	DllCall("BitBlt", "Ptr", hNoteMemDC, "Int", 0, "Int", 0, "Int", NoteW, "Int", NoteFullH
		, "Ptr", hNoteScreenDC, "Int", nwx + NoteOriginX, "Int", nwy + NoteOriginY, "UInt", 0x00CC0020)
}

NoteParseColors() {
	global NoteColor, NoteColorCached, NoteColR, NoteColG, NoteColB, NoteColN
	if (NoteColor = NoteColorCached)
		return NoteColN
	NoteColorCached := NoteColor
	NoteColR := []
	NoteColG := []
	NoteColB := []
	NoteColN := 0
	Loop, Parse, NoteColor, `,; , %A_Space%%A_Tab%
		{
		s := A_LoopField
		if (s = "")
			continue
		if (SubStr(s, 1, 2) = "0x")
			s := SubStr(s, 3)
		if (!RegExMatch(s, "^[0-9a-fA-F]{6}$"))
			continue
		v := "0x" . s
		NoteColN := NoteColN + 1
		NoteColR.Push((v >> 16) & 0xFF)
		NoteColG.Push((v >> 8) & 0xFF)
		NoteColB.Push(v & 0xFF)
		}
	return NoteColN
}

NoteScanFind(lockX) {
	global pNoteBits, NoteW, NoteH, NoteColorTolerance
	global NoteColR, NoteColG, NoteColB, NoteColN
	global NoteDbgPx, NoteDbgRun, NoteDbgBest
	NoteDbgPx := 0
	NoteDbgRun := 0
	NoteDbgBest := "-"
	if (!pNoteBits)
		return -1
	if (NoteParseColors() < 1)
		return -1
	tol := NoteColorTolerance
	if (tol < 6)
		tol := 6
	if (tol > 25)
		tol := 25
	yStep := (lockX >= 0) ? 8 : 16
	xFrom := 0
	xTo := NoteW
	if (lockX >= 0)
		{
		xFrom := Round(lockX) - 80
		xTo := Round(lockX) + 80
		if (xFrom < 0)
			xFrom := 0
		if (xTo > NoteW)
			xTo := NoteW
		}
	y := NoteH - 13
	while (y >= 0)
		{
		off := y * NoteW * 4
		runs := []
		runStart := -1
		x := xFrom
		while (x < xTo)
			{
			v := NumGet(pNoteBits + 0, off + (x*4), "UInt")
			b := v & 0xFF
			g := (v >> 8) & 0xFF
			r := (v >> 16) & 0xFF
			ok := false
			ci := 1
			while (ci <= NoteColN)
				{
				if (Abs(r - NoteColR[ci]) <= tol and Abs(g - NoteColG[ci]) <= tol and Abs(b - NoteColB[ci]) <= tol)
					{
					ok := true
					break
					}
				ci++
				}
			if (ok)
				{
				NoteDbgPx := NoteDbgPx + 1
				if (runStart < 0)
					runStart := x
				}
			else if (runStart >= 0)
				{
				if (x - runStart > NoteDbgRun)
					{
					NoteDbgRun := x - runStart
					NoteDbgBest := "x" . runStart . "y" . y
					}
				if (x - runStart >= 8)
					runs.Push(runStart, x - 1)
				runStart := -1
				}
			x += 4
			}
		if (runStart >= 0 and xTo - runStart >= 8)
			runs.Push(runStart, xTo - 1)

		n := runs.Length() // 2
		if (n > 0)
			{
			gi := 1
			while (gi <= n)
				{
				gl := runs[(gi-1)*2 + 1]
				gr := runs[(gi-1)*2 + 2]
				gj := gi + 1
				while (gj <= n)
					{
					nl := runs[(gj-1)*2 + 1]
					if (nl - gr > 45)
						break
					gr := runs[(gj-1)*2 + 2]
					gj++
					}
				w := gr - gl + 1
				if (w >= 8 and w <= 120)
					{
					cx := gl + (w / 2)
					if (lockX < 0 or Abs(cx - lockX) <= 55)
						return cx
					}
				gi := gj
				}
			}
		y -= yStep
		}
	return -1
}

LullRing(rr) {
	global pNoteBits, NoteW, NoteFullH, NoteTop, FishBarTop, CaptureW, LullPivotUp
	out := []
	if (!pNoteBits or rr < 20)
		return out
	bx := Round(CaptureW / 2)
	by := Round((FishBarTop - LullPivotUp) - NoteTop)
	d := 180
	while (d <= 360)
		{
		th := d * 0.01745329252
		x := Round(bx + (rr * Cos(th)))
		y := Round(by + (rr * Sin(th)))
		if (x >= 0 and x < NoteW and y >= 0 and y < NoteFullH)
			{
			px := NumGet(pNoteBits + 0, ((y * NoteW) + x) * 4, "UInt")
			out[d] := ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
			}
		else
			out[d] := -1
		d := d + 2
		}
	return out
}

LullCalStep() {
	global CaptureW, LullCalN, LullCalLt, LullCalDk, LullCalLs, LullRadiusPct
	i := 0
	while (i < 14)
		{
		rr := Round(CaptureW * (7 + (i * 1.2)) / 100)
		v := LullRing(rr)
		d := 180
		while (d <= 360)
			{
			if (v[d] != "" and v[d] >= 0)
				{
				ky := (i * 1000) + d
				if (v[d] >= 140)
					{
					LullCalLt[ky] := ((LullCalLt[ky] = "") ? 0 : LullCalLt[ky]) + 1
					LullCalLs[ky] := ((LullCalLs[ky] = "") ? 0 : LullCalLs[ky]) + v[d]
					}
				else if (v[d] < 40)
					LullCalDk[ky] := ((LullCalDk[ky] = "") ? 0 : LullCalDk[ky]) + 1
				}
			d := d + 2
			}
		i := i + 1
		}
	LullCalN := LullCalN + 1
}

LullPickRadius() {
	global CaptureW, LullCalLt, LullCalDk, LullCalLs, LullR, LullBg, LullLightLum
	bestSc := -1
	bestI := -1
	i := 0
	while (i < 14)
		{
		nl := 0
		nd := 0
		nt := 0
		d := 180
		while (d <= 360)
			{
			ky := (i * 1000) + d
			lt := (LullCalLt[ky] = "") ? 0 : LullCalLt[ky]
			dk := (LullCalDk[ky] = "") ? 0 : LullCalDk[ky]
			if (lt > 0 or dk > 0)
				{
				nt := nt + 1
				if (lt > dk)
					nl := nl + 1
				else if (dk > lt)
					nd := nd + 1
				}
			d := d + 2
			}
		if (nt >= 30 and nd > bestSc)
			{
			bestSc := nd
			bestI := i
			}
		i := i + 1
		}
	if (bestI >= 0)
		{
		nl2 := 0
		d := 180
		while (d <= 360)
			{
			ky := (bestI * 1000) + d
			if (LullCalLt[ky] != "" and LullCalLt[ky] > 0)
				nl2 := nl2 + 1
			d := d + 2
			}
		if (nl2 < 2)
			bestI := -1
		}
	if (bestI < 0)
		{
		LullR := Round(CaptureW * LullRadiusPct / 100)
		return 0
		}
	LullR := Round(CaptureW * (7 + (bestI * 1.2)) / 100)
	LullBg := []
	d := 180
	while (d <= 360)
		{
		ky := (bestI * 1000) + d
		lt := (LullCalLt[ky] = "") ? 0 : LullCalLt[ky]
		dk := (LullCalDk[ky] = "") ? 0 : LullCalDk[ky]
		if (lt > dk and lt > 0)
			LullBg[d] := LullCalLs[ky] / lt
		else
			LullBg[d] := 0
		d := d + 2
		}
	return LullR
}

LullFindSectors() {
	global LullBg, LullSecN, LullSecA, LullSecB, LullLightLum, LullMinDeg
	ll := LullLightLum
	if (ll < 30)
		ll := 30
	if (ll > 220)
		ll := 220
	md := LullMinDeg
	if (md < 2)
		md := 2
	if (md > 60)
		md := 60
	LullSecN := 0
	LullSecA := []
	LullSecB := []
	runS := -1
	d := 180
	while (d <= 362)
		{
		lit := false
		if (d <= 360 and LullBg[d] != "")
			lit := (LullBg[d] >= ll)
		if (lit)
			{
			if (runS < 0)
				runS := d
			}
		else if (runS >= 0)
			{
			if (((d - 2) - runS) >= (md - 2))
				{
				LullSecN := LullSecN + 1
				LullSecA[LullSecN] := runS
				LullSecB[LullSecN] := d - 2
				}
			runS := -1
			}
		d := d + 2
		}
	return LullSecN
}

LullScan() {
	global LullFrames, LullCalN, LullR, LullBg, LullSecN, LullSecA, LullSecB
	global LullArmA, LullClrT, LullActive, LullHitSec
	global LullArmDelta, LullTrigPct, LullClearMs, LullRadiusPct, CaptureW
	LullHitSec := 0
	probe := (LullR > 0) ? LullR : Round(CaptureW * LullRadiusPct / 100)
	v := LullRing(probe)
	vmn := 999
	vmx := -1
	d := 180
	while (d <= 360)
		{
		if (v[d] != "" and v[d] >= 0)
			{
			if (v[d] < vmn)
				vmn := v[d]
			if (v[d] > vmx)
				vmx := v[d]
			}
		d := d + 2
		}
	if (vmx < 0 or vmx < 120)
		{
		LullActive := false
		return false
		}
	LullActive := true
	LullFrames := LullFrames + 1
	if (LullR <= 0)
		{
		LullCalStep()
		if (LullCalN >= 26)
			{
			LullPickRadius()
			LullFindSectors()
			}
		return false
		}
	dv := LullArmDelta
	if (dv < 15)
		dv := 15
	if (dv > 200)
		dv := 200
	tp := LullTrigPct
	if (tp < 3)
		tp := 3
	if (tp > 90)
		tp := 90
	cm := LullClearMs
	if (cm < 20)
		cm := 20
	if (cm > 2000)
		cm := 2000
	now := A_TickCount
	hit := false
	i := 1
	while (i <= LullSecN)
		{
		ka := LullSecA[i]
		dk := 0
		n := 0
		d := ka
		while (d <= LullSecB[i])
			{
			if (v[d] != "" and v[d] >= 0 and LullBg[d] != "")
				{
				n := n + 1
				if (Abs(v[d] - LullBg[d]) >= dv)
					dk := dk + 1
				}
			d := d + 2
			}
		if (n > 0 and (dk * 100) >= (n * tp))
			{
			LullClrT[ka] := 0
			if (LullArmA[ka] = "" or LullArmA[ka])
				{
				LullArmA[ka] := false
				LullHitSec := i
				hit := true
				}
			}
		else
			{
			if (LullClrT[ka] = "" or LullClrT[ka] = 0)
				LullClrT[ka] := now
			if ((now - LullClrT[ka]) >= cm)
				LullArmA[ka] := true
			}
		i := i + 1
		}
	return hit
}

NoteScanAll() {
	global pNoteBits, NoteW, NoteH, NoteColorTolerance
	global NoteColR, NoteColG, NoteColB, NoteColN
	global NoteAllX, NoteAllY, NoteAllN
	NoteAllX := []
	NoteAllY := []
	NoteAllN := 0
	sumX := []
	cntX := []
	if (!pNoteBits)
		return 0
	if (NoteParseColors() < 1)
		return 0
	tol := NoteColorTolerance
	if (tol < 6)
		tol := 6
	if (tol > 25)
		tol := 25
	c1r := NoteColR[1]
	c1g := NoteColG[1]
	c1b := NoteColB[1]
	r1lo := c1r - tol
	r1hi := c1r + tol
	g1lo := c1g - tol
	g1hi := c1g + tol
	b1lo := c1b - tol
	b1hi := c1b + tol
	multi := (NoteColN > 1)
	y := NoteH - 13
	while (y >= 0)
		{
		off := y * NoteW * 4
		runs := []
		runStart := -1
		x := 0
		while (x < NoteW)
			{
			v := NumGet(pNoteBits + 0, off + (x*4), "UInt")
			b := v & 0xFF
			ok := false
			if (b >= b1lo and b <= b1hi)
				{
				g := (v >> 8) & 0xFF
				if (g >= g1lo and g <= g1hi)
					{
					r := (v >> 16) & 0xFF
					ok := (r >= r1lo and r <= r1hi)
					}
				}
			if (!ok and multi)
				{
				g := (v >> 8) & 0xFF
				r := (v >> 16) & 0xFF
				ci := 2
				while (ci <= NoteColN)
					{
					if (Abs(r - NoteColR[ci]) <= tol and Abs(g - NoteColG[ci]) <= tol and Abs(b - NoteColB[ci]) <= tol)
						{
						ok := true
						break
						}
					ci++
					}
				}
			if (ok)
				{
				if (runStart < 0)
					runStart := x
				}
			else if (runStart >= 0)
				{
				if (x - runStart >= 8)
					runs.Push(runStart, x - 1)
				runStart := -1
				}
			x += 4
			}
		if (runStart >= 0 and NoteW - runStart >= 8)
			runs.Push(runStart, NoteW - 1)
		n := runs.Length() // 2
		if (n > 0)
			{
			gi := 1
			while (gi <= n)
				{
				gl := runs[(gi-1)*2 + 1]
				gr := runs[(gi-1)*2 + 2]
				gj := gi + 1
				while (gj <= n)
					{
					nl := runs[(gj-1)*2 + 1]
					if (nl - gr > 45)
						break
					gr := runs[(gj-1)*2 + 2]
					gj++
					}
				w := gr - gl + 1
				if (w >= 8 and w <= 120)
					{
					cx := gl + (w / 2)
					dup := false
					di := 1
					while (di <= NoteAllN)
						{
						if (Abs(cx - NoteAllX[di]) <= 55 and (NoteAllY[di] - y) <= 120)
							{
							sumX[di] := sumX[di] + cx
							cntX[di] := cntX[di] + 1
							NoteAllX[di] := sumX[di] / cntX[di]
							dup := true
							break
							}
						di++
						}
					if (!dup and NoteAllN < 2)
						{
						NoteAllN++
						NoteAllX[NoteAllN] := cx
						NoteAllY[NoteAllN] := y
						sumX[NoteAllN] := cx
						cntX[NoteAllN] := 1
						}
					}
				gi := gj
				}
			}
		if (NoteAllN >= 2)
			break
		y -= 16
		}
	return NoteAllN
}

NoteScan(refX) {
	global FishBarLeft, FishBarRight, NoteOriginX, NoteLockX, NoteLockN, LastNoteX, NoteDbgCalls, NoteMissN
	global NoteFresh, NoteIndep, NoteMissAt, QpcFreq
	global NoteAllX, NoteAllY, NoteAllN, NoteH, NoteHandoff
	global NoteNextX, NoteLockY, NoteNextY
	NoteDbgCalls := NoteDbgCalls + 1
	if (NoteIndep and !NoteFresh and NoteLockX >= 0)
		{
		LastNoteX := NoteLockX
		return NoteLockX
		}
	LastNoteX := -1
	NoteNextX := -1
	NoteNextY := -1
	if (NoteScanAll() < 1)
		{
		DllCall("QueryPerformanceCounter", "Int64*", NoteMissNow)
		if (!NoteMissAt)
			NoteMissAt := NoteMissNow
		if (NoteLockX >= 0 and ((NoteMissNow - NoteMissAt) * 1000.0 / QpcFreq) <= 260)
			{
			LastNoteX := NoteLockX
			return NoteLockX
			}
		NoteLockX := -1
		NoteLockN := 0
		NoteLockY := -1
		NoteMissAt := 0
		return -1
		}
	NoteMissAt := 0
	sel := 1
	matched := false
	if (NoteLockX >= 0)
		{
		i := 1
		while (i <= NoteAllN)
			{
			if (Abs((NoteOriginX + NoteAllX[i]) - NoteLockX) <= 55
				and (NoteLockY < 0 or NoteAllY[i] <= NoteLockY + 100))
				{
				sel := i
				matched := true
				break
				}
			i++
			}
		}
	hoff := NoteHandoff
	if (hoff < 0)
		hoff := 0
	if (hoff > 200)
		hoff := 200
	if (NoteAllN > sel and hoff > 0 and NoteAllY[sel] > (NoteH - 13 - hoff))
		{
		sel := sel + 1
		matched := false
		}
	newX := NoteOriginX + NoteAllX[sel]
	if (newX < FishBarLeft)
		newX := FishBarLeft
	if (newX > FishBarRight)
		newX := FishBarRight
	if (!matched)
		{
		NoteLockX := newX
		NoteLockN := 1
		}
	else
		{
		NoteLockN := NoteLockN + 1
		nAvg := (NoteLockN < 8) ? NoteLockN : 8
		NoteLockX := NoteLockX + ((newX - NoteLockX) / nAvg)
		}
	NoteLockY := NoteAllY[sel]
	LastNoteX := NoteLockX
	if (NoteAllN > sel)
		{
		NoteNextX := NoteOriginX + NoteAllX[sel + 1]
		if (NoteNextX < FishBarLeft)
			NoteNextX := FishBarLeft
		if (NoteNextX > FishBarRight)
			NoteNextX := FishBarRight
		NoteNextY := NoteAllY[sel + 1]
		}
	return NoteLockX
}

CapUnionDC(w, h) {
	global hCapUnionDC, hCapUnionBM, CapUW, CapUH, hCaptureScreenDC
	if (hCapUnionDC and w <= CapUW and h <= CapUH)
		return true
	if (hCapUnionDC)
		{
		DllCall("DeleteObject", "Ptr", hCapUnionBM)
		DllCall("DeleteDC", "Ptr", hCapUnionDC)
		hCapUnionDC := 0
		}
	if (!hCaptureScreenDC)
		return false
	hCapUnionDC := DllCall("CreateCompatibleDC", "Ptr", hCaptureScreenDC, "Ptr")
	hCapUnionBM := DllCall("CreateCompatibleBitmap", "Ptr", hCaptureScreenDC, "Int", w, "Int", h, "Ptr")
	if (!hCapUnionDC or !hCapUnionBM)
		{
		if (hCapUnionDC)
			DllCall("DeleteDC", "Ptr", hCapUnionDC)
		hCapUnionDC := 0
		return false
		}
	DllCall("SelectObject", "Ptr", hCapUnionDC, "Ptr", hCapUnionBM)
	CapUW := w
	CapUH := h
	return true
}

CaptureStrip() {
	global hCaptureMemDC, hCaptureScreenDC, CaptureW, CaptureH, FishBarLeft, FishBarTop, RobloxHwnd
	global hNoteMemDC, NoteW, NoteH, NoteFullH, NoteTop
	global pNoteBits, pCaptureBits, pCaptureOwn
	global NoteIndep, NoteOriginX, NoteOriginY, NoteNeeded
	global NoteFresh, NoteBlitAt, NoteRefreshMs, QpcFreq, NoteLockX, CapExtra, SwMaxSigns, SpecialRod, hCapUnionDC
	RobloxClientRect(RobloxHwnd, cwx, cwy)
	if (!NoteNeeded)
		{
		pCaptureBits := pCaptureOwn
		DllCall("BitBlt", "Ptr", hCaptureMemDC, "Int", 0, "Int", 0, "Int", CaptureW, "Int", CaptureH + 38 + CapExtra
			, "Ptr", hCaptureScreenDC, "Int", cwx + Round(FishBarLeft), "Int", cwy + Round(FishBarTop) - 18, "UInt", 0x00CC0020)
		return
		}
	if (NoteIndep and hNoteMemDC)
		{
		DllCall("QueryPerformanceCounter", "Int64*", NoteNowT)
		if (SpecialRod = "Stellarwave Melody" and NoteFullH > NoteH)
			{
			NoteFresh := true
			NoteBlitAt := NoteNowT
			DllCall("BitBlt", "Ptr", hNoteMemDC, "Int", 0, "Int", 0, "Int", NoteW, "Int", NoteFullH
				, "Ptr", hCaptureScreenDC, "Int", cwx + NoteOriginX, "Int", cwy + NoteOriginY, "UInt", 0x00CC0020)
			pCaptureBits := pCaptureOwn
			DllCall("BitBlt", "Ptr", hCaptureMemDC, "Int", 0, "Int", 0, "Int", CaptureW, "Int", CaptureH + 38 + CapExtra
				, "Ptr", hNoteMemDC, "Int", Round(FishBarLeft) - NoteOriginX, "Int", Round(FishBarTop) - 18 - NoteOriginY, "UInt", 0x00CC0020)
			return
			}
		NoteRefreshMs := (SwMaxSigns and SpecialRod = "Stellarwave Melody") ? 0 : ((NoteLockX >= 0) ? 80 : 45)
		NoteFresh := (!NoteBlitAt or ((NoteNowT - NoteBlitAt) * 1000.0 / QpcFreq) >= NoteRefreshMs)
		if (NoteFresh)
			{
			NoteBlitAt := NoteNowT
			nx := cwx + NoteOriginX
			ny := cwy + NoteOriginY
			bx := cwx + Round(FishBarLeft)
			by := cwy + Round(FishBarTop) - 18
			bh := CaptureH + 38 + CapExtra
			ux := (nx < bx) ? nx : bx
			uy := (ny < by) ? ny : by
			uw := ((nx + NoteW > bx + CaptureW) ? nx + NoteW : bx + CaptureW) - ux
			uh := ((ny + NoteFullH > by + bh) ? ny + NoteFullH : by + bh) - uy
			if (uw * uh <= 4 * (NoteW * NoteFullH + CaptureW * bh) and CapUnionDC(uw, uh))
				{
				DllCall("BitBlt", "Ptr", hCapUnionDC, "Int", 0, "Int", 0, "Int", uw, "Int", uh, "Ptr", hCaptureScreenDC, "Int", ux, "Int", uy, "UInt", 0x00CC0020)
				DllCall("BitBlt", "Ptr", hNoteMemDC, "Int", 0, "Int", 0, "Int", NoteW, "Int", NoteFullH, "Ptr", hCapUnionDC, "Int", nx - ux, "Int", ny - uy, "UInt", 0x00CC0020)
				pCaptureBits := pCaptureOwn
				DllCall("BitBlt", "Ptr", hCaptureMemDC, "Int", 0, "Int", 0, "Int", CaptureW, "Int", bh, "Ptr", hCapUnionDC, "Int", bx - ux, "Int", by - uy, "UInt", 0x00CC0020)
				return
				}
			DllCall("BitBlt", "Ptr", hNoteMemDC, "Int", 0, "Int", 0, "Int", NoteW, "Int", NoteFullH
				, "Ptr", hCaptureScreenDC, "Int", cwx + NoteOriginX, "Int", cwy + NoteOriginY, "UInt", 0x00CC0020)
			}
		pCaptureBits := pCaptureOwn
		DllCall("BitBlt", "Ptr", hCaptureMemDC, "Int", 0, "Int", 0, "Int", CaptureW, "Int", CaptureH + 38 + CapExtra
			, "Ptr", hCaptureScreenDC, "Int", cwx + Round(FishBarLeft), "Int", cwy + Round(FishBarTop) - 18, "UInt", 0x00CC0020)
		return
		}
	if (hNoteMemDC and NoteFullH > CaptureH)
		{
		DllCall("BitBlt", "Ptr", hNoteMemDC, "Int", 0, "Int", 0, "Int", NoteW, "Int", NoteFullH
			, "Ptr", hCaptureScreenDC, "Int", cwx + Round(FishBarLeft), "Int", cwy + Round(NoteTop), "UInt", 0x00CC0020)
		if (NoteW = CaptureW and pNoteBits)
			pCaptureBits := pNoteBits + (NoteH * NoteW * 4)
		else
			{
			pCaptureBits := pCaptureOwn
			DllCall("BitBlt", "Ptr", hCaptureMemDC, "Int", 0, "Int", 0, "Int", CaptureW, "Int", CaptureH + 38
				, "Ptr", hNoteMemDC, "Int", 0, "Int", NoteH - 18, "UInt", 0x00CC0020)
			}
		return
		}
	pCaptureBits := pCaptureOwn
	DllCall("BitBlt", "Ptr", hCaptureMemDC, "Int", 0, "Int", 0, "Int", CaptureW, "Int", CaptureH + 38 + CapExtra
		, "Ptr", hCaptureScreenDC, "Int", cwx + Round(FishBarLeft), "Int", cwy + Round(FishBarTop) - 18, "UInt", 0x00CC0020)
}

CaptureEdgeStrips() {
	global UiEdgeOn, pCaptureBits, pUiEdgeBits, CaptureW
	if (!UiEdgeOn or !pCaptureBits)
		return
	pUiEdgeBits := pCaptureBits - (18 * CaptureW * 4)
}

UiEdgeFrac(r, step) {
	global pUiEdgeBits, CaptureW, UiEdgeH
	if (!pUiEdgeBits or r < 2 or r > UiEdgeH - 3 or CaptureW < 8)
		return 0
	oA := (r - 2) * CaptureW * 4
	oB := (r + 2) * CaptureW * 4
	n := 0
	hit := 0
	x := 0
	while (x < CaptureW)
		{
		pa := NumGet(pUiEdgeBits + 0, oA + (x * 4), "UInt")
		pb := NumGet(pUiEdgeBits + 0, oB + (x * 4), "UInt")
		la := ((pa & 0xFF) + ((pa >> 8) & 0xFF) + ((pa >> 16) & 0xFF)) // 3
		lb := ((pb & 0xFF) + ((pb >> 8) & 0xFF) + ((pb >> 16) & 0xFF)) // 3
		d := la - lb
		if (d < 0)
			d := 0 - d
		if (d >= 20)
			hit := hit + 1
		n := n + 1
		x := x + step
		}
	return n ? (hit / n) : 0
}

UiEdgeBandMax(r0, r1, rstep, cstep, ByRef bestR) {
	best := 0
	bestR := r0
	r := r0
	while (r <= r1)
		{
		f := UiEdgeFrac(r, cstep)
		if (f > best)
			{
			best := f
			bestR := r
			}
		r := r + rstep
		}
	return best
}

TrackEdgesVisible() {
	global UiTopRows, UiBotOff, UiEdgeH, UiGateN
	UiGateN := (UiGateN >= 0 and UiGateN < 3) ? UiGateN + 1 : 0
	tM := UiEdgeBandMax(2 + Mod(UiGateN, 2), UiTopRows - 3, 2, 8, rt)
	bM := UiEdgeBandMax(UiBotOff + 2 + (UiGateN // 2), UiEdgeH - 3, 2, 8, rb)
	return ((tM >= 0.5 and bM >= 0.35) or (bM >= 0.5 and tM >= 0.35))
}

UiStartGate() {
	global UiPhantomT, QpcFreq, UiEdgesKnownGood
	if (TrackEdgesVisible())
		{
		UiPhantomT := 0
		return true
		}
	DllCall("QueryPerformanceCounter", "Int64*", gnow)
	if (!UiPhantomT)
		{
		UiPhantomT := gnow
		return false
		}
	if (((gnow - UiPhantomT) / QpcFreq) >= (UiEdgesKnownGood ? 4.0 : 0.5))
		{
		UiPhantomT := 0
		UiEdgesKnownGood := false
		return true
		}
	return false
}

UiEdgeReset() {
	global UiState, UiPhantomT, UiGoneT, UiGreenT, UiCallN, UiLearnT, UiLearnN, UiAccT, UiAccB
	global UiEdgeTY, UiEdgeBY, UiPeakT, UiPeakB, UiThr, UiCntT, UiCntB, UiEdgeLatch, UiArmT, UiFightT0, UiLastGone
	UiState := 0
	UiArmT := 0
	UiFightT0 := 0
	UiLastGone := false
	UiPhantomT := 0
	UiGoneT := 0
	UiGreenT := 0
	UiCallN := 0
	UiLearnT := 0
	UiLearnN := 0
	UiAccT := {}
	UiAccB := {}
	UiCntT := {}
	UiCntB := {}
	UiEdgeLatch := false
	UiEdgeTY := -1
	UiEdgeBY := -1
	UiPeakT := 0
	UiPeakB := 0
	UiThr := 9
}

UiEdgeStart() {
	global UiState, UiLearnT, UiLearnN, UiAccT, UiAccB, UiGoneT, UiGreenT, UiEdgeOn, UiFightT0
	UiEdgeReset()
	if (!UiEdgeOn)
		{
		UiState := 3
		return
		}
	DllCall("QueryPerformanceCounter", "Int64*", UiLearnT)
	UiFightT0 := UiLearnT
	UiState := 1
}

UiEdgeTick() {
	global UiState, UiLearnT, UiLearnN, UiAccT, UiAccB, UiEdgeTY, UiEdgeBY, UiPeakT, UiPeakB, UiThr
	global UiGoneT, UiGreenT, UiCallN, UiTopRows, UiBotOff, UiEdgeH, QpcFreq, UiEdgesKnownGood
	global UiCntT, UiCntB, UiEdgeLatch, UiTopStart, UiLatchMs, UiFightT0, UiArmT, UiResumeF, UiLastGone
	if (UiState = 0)
		return "off"
	DllCall("QueryPerformanceCounter", "Int64*", unow)
	UiCallN := UiCallN + 1
	if (UiState = 1)
		{
		if (Mod(UiCallN, 2) = 0)
			{
			UiLearnRot := Mod(UiLearnN, 3)
			r := ((UiTopStart >= 2) ? UiTopStart : 2) + UiLearnRot
			while (r <= UiTopRows - 3)
				{
				UiAccT[r] := (UiAccT.HasKey(r) ? UiAccT[r] : 0) + UiEdgeFrac(r, 8)
				UiCntT[r] := (UiCntT.HasKey(r) ? UiCntT[r] : 0) + 1
				r := r + 3
				}
			r := UiBotOff + 2 + UiLearnRot
			while (r <= UiEdgeH - 3)
				{
				UiAccB[r] := (UiAccB.HasKey(r) ? UiAccB[r] : 0) + UiEdgeFrac(r, 8)
				UiCntB[r] := (UiCntB.HasKey(r) ? UiCntB[r] : 0) + 1
				r := r + 3
				}
			UiLearnN := UiLearnN + 1
			}
		if (UiLearnN >= 9 and ((unow - UiLearnT) / QpcFreq) >= 0.5)
			{
			bT := -1
			bTv := -1
			for k, v in UiAccT
				{
				v := v / UiCntT[k]
				if (v > bTv)
					{
					bTv := v
					bT := k
					}
				}
			bB := -1
			bBv := -1
			for k, v in UiAccB
				{
				v := v / UiCntB[k]
				if (v > bBv)
					{
					bBv := v
					bB := k
					}
				}
			UiPeakT := (bT >= 0) ? bTv : 0
			UiPeakB := (bB >= 0) ? bBv : 0
			if (UiPeakT < 0.4 or UiPeakB < 0.4)
				{
				if (((unow - UiFightT0) / QpcFreq) < 3.0)
					{
					UiEdgeRelearn(unow)
					return "learning"
					}
				UiState := 3
				return "present"
				}
			UiEdgeBandMax(bT - 1, bT + 1, 1, 2, rt)
			UiEdgeBandMax(bB - 1, bB + 1, 1, 2, rb)
			UiEdgeTY := rt
			UiEdgeBY := rb
			UiThr := 0.5 * (UiPeakT + UiPeakB)
			UiState := 2
			UiArmT := unow
			UiEdgesKnownGood := true
			}
		return "learning"
		}
	if (UiState = 2 and Mod(UiCallN, 2) = 0)
		{
		sT := UiEdgeFrac(UiEdgeTY, 3)
		sB := UiEdgeFrac(UiEdgeBY, 3)
		if (sT >= 0.5 * UiPeakT or (sT >= 0.25 * UiPeakT and sB >= 0.5 * UiPeakB))
			{
			UiLastGone := false
			if (!UiEdgeLatch and (!UiGoneT or (sT >= UiResumeF * UiPeakT and sB >= UiResumeF * UiPeakB) or ((unow - UiGoneT) * 1000.0 / QpcFreq) >= 500))
				{
				UiGoneT := 0
				UiGreenT := 0
				}
			}
		else
			{
			UiLastGone := true
			if (!UiGoneT)
				UiGoneT := unow
			else if (((unow - UiGoneT) * 1000.0 / QpcFreq) >= UiLatchMs)
				UiEdgeLatch := true
			if (!UiEdgeLatch and ((unow - UiArmT) / QpcFreq) < 1.5 and (UiEdgeBandMax(UiTopStart, UiTopRows - 3, 1, 8, UiRelearnRow) >= 0.5 * UiPeakT or UiEdgeBandMax(UiBotOff + 2, UiEdgeH - 3, 1, 8, UiRelearnRow) >= 0.5 * UiPeakB))
				{
				UiEdgeRelearn(unow)
				return "learning"
				}
			}
		}
	if ((UiState = 3 and Mod(UiCallN, 10) = 0) or (UiState = 2 and UiGoneT and Mod(UiCallN, 3) = 0))
		{
		if (GreenCornerPresent())
			{
			if (!UiGreenT)
				UiGreenT := unow
			}
		else
			UiGreenT := 0
		}
	goneMs := UiGoneT ? ((unow - UiGoneT) * 1000.0 / QpcFreq) : 0
	greenMs := UiGreenT ? ((unow - UiGreenT) * 1000.0 / QpcFreq) : 0
	if (UiState = 2 and goneMs >= 500 and (UiEdgeLatch or UiLastGone))
		return "gone"
	if (UiState = 2 and goneMs >= 200 and greenMs >= 200)
		return "gone"
	if (UiState = 3 and greenMs >= 800)
		return "gone"
	return "present"
}

UiHandsOff(uhTick) {
	global UiEdgeLatch
	global UiGoneT, UiState, SpecialRod, PrecisionDown, PrecisionUpAt, MaxLeftToggle, MaxRightToggle, BelDown, UiCallN, DarkFlashing
	if (SpecialRod = "Tranquility" or SpecialRod = "Lullaby" or SpecialRod = "Stellarwave Melody")
		return false
	if (uhTick and UiState = 2)
		{
		if (Mod(UiCallN, 2) = 0)
			UiCallN := UiCallN + 1
		UiEdgeTick()
		}
	if (!UiGoneT)
		return false
	if (SpecialRod = "Darkheart" and (DarkFlashing or FrameIsDark()))
		return false
	if (BarPresent() or FishLineVisible())
		return false
	MaxLeftToggle := false
	MaxRightToggle := false
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
		}
	if (SpecialRod = "Bellona's Waraxe" and (BelDown[1] or BelDown[2] or GetKeyState("RButton")))
		BellonaRelease()
	return true
}

UiEdgeRelearn(ut) {
	global UiState, UiLearnT, UiLearnN, UiAccT, UiAccB, UiCntT, UiCntB, UiGoneT, UiGreenT, UiCallN, UiLastGone
	UiState := 1
	UiLastGone := false
	UiLearnT := ut
	UiLearnN := 0
	UiAccT := {}
	UiAccB := {}
	UiCntT := {}
	UiCntB := {}
	UiGoneT := 0
	UiGreenT := 0
	UiCallN := 1
}

GreenCornerPresent() {
	global hUiGrnDC, pUiGrnBits, hCaptureScreenDC, UiGrnW, UiGrnH, RobloxHwnd
	if (!hUiGrnDC or !pUiGrnBits)
		return false
	RobloxClientRect(RobloxHwnd, cwx, cwy, cww, cwh)
	DllCall("BitBlt", "Ptr", hUiGrnDC, "Int", 0, "Int", 0, "Int", UiGrnW, "Int", UiGrnH
		, "Ptr", hCaptureScreenDC, "Int", cwx, "Int", cwy + Round(cwh * 0.90), "UInt", 0x00CC0020)
	cnt := 0
	y := 0
	while (y < UiGrnH)
		{
		off := y * UiGrnW * 4
		x := 0
		while (x < UiGrnW)
			{
			px := NumGet(pUiGrnBits + 0, off + (x * 4), "UInt")
			if (((px >> 8) & 0xFF) >= 240)
				{
				pr := (px >> 16) & 0xFF
				pb := px & 0xFF
				if (pr >= 140 and pr <= 170 and pb >= 140 and pb <= 170)
					{
					cnt := cnt + 1
					if (cnt >= 3)
						return true
					}
				}
			x := x + 3
			}
		y := y + 3
		}
	return false
}

ClampPct(v, lo, hi) {
	if (v = "" or v < lo)
		return lo
	if (v > hi)
		return hi
	return v
}

PreciseSleep(ms) {
	global QpcFreq
	if (ms <= 0)
		return
	DllCall("QueryPerformanceCounter", "Int64*", tNow)
	tEnd := tNow + Round(ms * QpcFreq / 1000)
	Loop
		{
		DllCall("QueryPerformanceCounter", "Int64*", tNow)
		if (tNow >= tEnd)
			return
		Sleep, -1
		}
}

; how long the bar must be gone before the fight counts as over - a negative Adaptive Cast ms shortens it
BarLostLim() {
	global AdaptiveCast, AdaptiveCastMs
	lim := TA("barlost", 450)
	ac := AdaptiveCastMs
	if ac is not number
		return lim
	if (AdaptiveCast and ac < 0)
		lim := (lim + ac < 200) ? 200 : lim + ac
	return lim
}

; the version shown everywhere comes from the build number: 43 = 2.0, 44 = 2.01, 45 = 2.02 ...
DFVerName(b) {
	b := Round(b)
	if (b <= 43)
		return "2.0"
	return "2." . Format("{:02}", b - 43)
}

Tm(ms) {
	global TimeOffset, TmDebt, TmDebtT
	if ms is not number
		return ms
	if (ms >= 0 and ms <= 1)
		return ms
	off := TimeOffset
	if off is not number
		off := 0
	if TmDebt is not number
		TmDebt := 0
	d := (TmDebt < 0 and A_TickCount - TmDebtT < 5000) ? TmDebt : 0
	TmDebt := 0
	rem := ms + d
	if (rem < 0)
		{
		TmDebt := rem
		TmDebtT := A_TickCount
		return 0
		}
	v := Round(rem + off)
	return (v < 0) ? 0 : v
}

TmNumOpt(name) {
	return InStr(name, "Delay") ? "" : "+Number"
}

TA(id, def) {
	global AdvancedOn, AdvT
	if (!AdvancedOn)
		return def
	if (!IsObject(AdvT))
		AdvLoad()
	if (AdvT.HasKey(id))
		{
		v := AdvT[id]
		if v is number
			return v
		}
	return def
}

AdvLoad() {
	global AdvT, SettingsFile
	AdvT := {}
	for i, e in AdvRegistry()
		{
		if (e[2] != "L")
			continue
		IniRead, v, %SettingsFile%, Advanced, % e[3], %A_Space%
		if v is number
			AdvT[e[3]] := v + 0
		}
}

AdvRegistry() {
	static r := ""
	if (IsObject(r))
		return r
	r := []
	r.Push(["Window", "L", "winback", 1000, "ms|Wait while the Roblox window is missing"])
	r.Push(["Window", "L", "winfocus", 100, "ms|Pause after pulling Roblox back to the front"])
	r.Push(["Casting", "V", "RestartDelay", 0, "ms|Restart delay after a catch"])
	r.Push(["Casting", "V", "HoldRodCastDuration", 0, "ms|Cast hold (how long the click is held)"])
	r.Push(["Casting", "L", "castpost", 120, "ms|Smart cast: keep looking for the power bar after letting go"])
	r.Push(["Casting", "L", "castretry", 150, "ms|Smart cast: pause before recasting"])
	r.Push(["Casting", "L", "castgap", 50, "ms|Smart cast: extra wait between casts (on top of cast hold)"])
	r.Push(["Casting", "L", "passivelost", 3000, "ms|Passive: go back to watching if the minigame is gone for"])
	r.Push(["Casting", "V", "WaitForBobberDelay", 0, "ms|Wait for the bobber after casting"])
	r.Push(["Casting", "L", "chg", 40, "ms|Charged-cast check: pause before the second look"])
	r.Push(["Casting", "L", "reeq1", 120, "ms|Re-equip rod: pause before switching away"])
	r.Push(["Casting", "L", "reeq2", 400, "ms|Re-equip rod: pause between the two key presses"])
	r.Push(["Casting", "L", "reeq3", 600, "ms|Re-equip rod: pause after re-equipping"])
	r.Push(["Shake and failsafes", "V", "NavigationSpamDelay", 0, "ms|Shake: delay between Enter presses"])
	r.Push(["Shake and failsafes", "V", "NavigationShakeFailsafe", 0, "s|Shake failsafe - recast if no fish after"])
	r.Push(["Shake and failsafes", "V", "BarCalculationFailsafe", 0, "s|Bar failsafe - recast if the bar never shows after"])
	r.Push(["Minigame", "L", "barsamp", 12, "ms|Bar size: pause between samples"])
	r.Push(["Minigame", "L", "barhide", 150, "ms|Hide the overlay once the bar is gone for"])
	r.Push(["Minigame", "L", "barlost", 450, "ms|End the minigame once the bar is gone for"])
	r.Push(["Minigame", "L", "uigonefast", 0, "ms|End early once the UI and bar are both gone for"])
	r.Push(["Minigame", "L", "nofish", 8000, "ms|End the minigame if no fish line for"])
	r.Push(["Minigame", "L", "handsoff", 10, "ms|Pause while the bar UI is hidden"])
	r.Push(["Minigame", "L", "lullhold", 20, "ms|Lullaby: click hold"])
	r.Push(["Minigame", "L", "noiselost", 2000, "ms|Noiseform: end after the fish is lost for"])
	r.Push(["Minigame", "L", "twig1", 40, "ms|Splitbranch Twig: hover before clicking a fish"])
	r.Push(["Minigame", "L", "twig2", 40, "ms|Splitbranch Twig: click hold"])
	r.Push(["Minigame", "L", "twig3", 260, "ms|Splitbranch Twig: pause after clicking"])
	r.Push(["Stellarwave Melody", "L", "swallwait", 700, "ms|All signs: start anyway if no new sign for"])
	r.Push(["Stellarwave Melody", "L", "swretry", 250, "ms|Retry: wait before re-clicking"])
	r.Push(["Stellarwave Melody", "L", "ojwait", 600, "ms|Ouija: wait for the star before clicking again"])
	r.Push(["Stellarwave Melody", "L", "ojhover", 25, "ms|Ouija: hover before the click"])
	r.Push(["Stellarwave Melody", "L", "ojhold", 60, "ms|Ouija: click hold"])
	r.Push(["Stellarwave Melody", "L", "swendfast", 120, "ms|Fight over once the bar and stars are gone for"])
	r.Push(["Stellarwave Melody", "L", "swretrymax", 150, "ms|...same, with Max sign speed"])
	r.Push(["Stellarwave Melody", "L", "swrcneutral", 40, "ms|Retry click: pause at the neutral spot"])
	r.Push(["Stellarwave Melody", "L", "swrchover", 10, "ms|Retry click: hover before the nudge"])
	r.Push(["Stellarwave Melody", "L", "swrcwait", 20, "ms|Retry click: wait before clicking"])
	r.Push(["Stellarwave Melody", "L", "swrchold", 80, "ms|Retry click: click hold"])
	r.Push(["Stellarwave Melody", "V", "SwGuessWait", 0, "ms|Auto retry: wait for the star after a guess"])
	r.Push(["Stellarwave Melody", "L", "swgchover", 8, "ms|Auto retry guess: hover before the nudge"])
	r.Push(["Stellarwave Melody", "L", "swgcwait", 8, "ms|Auto retry guess: wait before clicking"])
	r.Push(["Stellarwave Melody", "L", "swgchold", 25, "ms|Auto retry guess: click hold"])
	r.Push(["Camera setup", "V", "AutoGraphicsDelay", 0, "ms|Auto-lower graphics delay"])
	r.Push(["Camera setup", "V", "AutoZoomDelay", 0, "ms|Auto-zoom delay"])
	r.Push(["Camera setup", "V", "AutoCameraDelay", 0, "ms|Auto camera mode delay"])
	r.Push(["Camera setup", "V", "AutoLookDelay", 0, "ms|Auto look-down delay"])
	r.Push(["Camera setup", "V", "AutoBlurDelay", 0, "ms|Auto blur delay"])
	r.Push(["Keeperbound recharge", "V", "KeeperOpenDelay", 0, "ms|Menu delay"])
	r.Push(["Keeperbound recharge", "V", "KeeperStepDelay", 0, "ms|Step delay"])
	r.Push(["Keeperbound recharge", "V", "KeeperBetweenDelay", 0, "ms|Between relics"])
	r.Push(["Keeperbound recharge", "L", "kbfocusto", 3, "s|Wait for Roblox to come to the front (max)"])
	r.Push(["Keeperbound recharge", "L", "kbfocus", 100, "ms|Pause after Roblox is in front"])
	r.Push(["Keeperbound recharge", "L", "kbinv1", 700, "ms|Look for an already-open inventory for"])
	r.Push(["Keeperbound recharge", "L", "kbinv2", 3000, "ms|Extra wait for the inventory to open"])
	r.Push(["Keeperbound recharge", "L", "kbconfto", 3500, "ms|Wait for the Confirm box to appear"])
	r.Push(["Keeperbound recharge", "L", "kbconfirm", 120, "ms|Pause before pressing Confirm"])
	r.Push(["Keeperbound recharge", "L", "kbgone", 3000, "ms|Wait for the Confirm box to close"])
	r.Push(["Keeperbound recharge", "L", "kbclose", 1200, "ms|Wait for the inventory to close"])
	r.Push(["Keeperbound recharge", "L", "kbclear", 900, "ms|Pause after closing a leftover dialog"])
	r.Push(["Keeperbound recharge", "L", "kbselect", 450, "ms|Most to wait for the rod to come back out"])
	r.Push(["Keeperbound recharge", "L", "kbrodsettle", 100, "ms|Wait after the power bar shows again"])
	r.Push(["Keeperbound recharge", "L", "kbfastwait", 400, "ms|Fast close: wait for the confirm box to fade"])
	r.Push(["Keeperbound recharge", "L", "kbclearwait", 250, "ms|Let a closing confirm box go by itself"])
	r.Push(["Keeperbound recharge", "L", "kbpoll", 40, "ms|Button search: check every"])
	r.Push(["Keeperbound recharge", "L", "kbgonepoll", 35, "ms|Close check: check every"])
	r.Push(["Keeperbound recharge", "L", "kbkey", 20, "ms|Pause after a key press"])
	r.Push(["Keeperbound recharge", "L", "kbtap1", 50, "ms|Button click: hover before clicking"])
	r.Push(["Keeperbound recharge", "L", "kbtap2", 35, "ms|Button click: click hold"])
	r.Push(["Keeperbound recharge", "L", "kbtap3", 30, "ms|Button click: pause after clicking"])
	r.Push(["Aquarium", "V", "AquariumOpenDelay", 0, "ms|Open delay"])
	r.Push(["Aquarium", "V", "AquariumStepDelay", 0, "ms|Step delay"])
	r.Push(["Aquarium", "L", "aqfocusto", 3, "s|Wait for Roblox to come to the front (max)"])
	r.Push(["Aquarium", "L", "aqfocus", 350, "ms|Pause after Roblox is in front"])
	r.Push(["Aquarium", "L", "aqpanel", 150, "ms|Panel check: check every"])
	r.Push(["Aquarium", "L", "aqwh1", 60, "ms|Scroll: hover before scrolling"])
	r.Push(["Aquarium", "L", "aqwh2", 30, "ms|Scroll: pause between wheel steps"])
	r.Push(["Aquarium", "L", "aqwh3", 130, "ms|Scroll: pause after scrolling"])
	r.Push(["Aquarium", "L", "aqtap", 55, "ms|Click: hover before clicking"])
	r.Push(["Totem", "V", "TotemActDelay", 0, "ms|Wait after using a totem"])
	r.Push(["Totem", "V", "TotemPollSec", 0, "s|Check for a totem every"])
	r.Push(["Totem", "L", "totemcatch", 0, "ms|Wait after a catch before using a totem"])
	r.Push(["Totem", "L", "totemsettle", 250, "ms|Pause while the totem bar settles"])
	r.Push(["Totem", "L", "totemkey", 300, "ms|Pause after selecting a totem before using it"])
	r.Push(["Totem", "L", "totemmax", 40000, "ms|Longest wait for the right time of day"])
	r.Push(["Totem", "L", "totemdone", 400, "ms|Pause after re-selecting the rod"])
	return r
}

SleepTrack(ms, dir := "", useArrow := false) {
	global MacroRunning, FishX, FishBarTooltipHeight, QpcFreq, RunLeft, RunWidth, HeldFraction
	HeldFraction := 1.0
	if (ms <= 15)
		{
		Sleep, % (ms < 0 ? 0 : ms)
		return
		}

	DllCall("QueryPerformanceCounter", "Int64*", tStart)
	Loop
		{
		if (!MacroRunning)
			return
		DllCall("QueryPerformanceCounter", "Int64*", tNow)
		elapsed := (tNow - tStart) * 1000.0 / QpcFreq
		remain := ms - elapsed
		if (remain <= 0)
			return
		if (remain <= 20)
			{

			Sleep, % Round(remain)
			return
			}
		CaptureStrip()
		if (UiHandsOff(true))
			return
		nx := GetFishPos()
		if (nx >= 0)
			{
			FishX := nx
			MoveHudFish(nx)
			}

		if (dir != "")
			{
			if (useArrow)
				bx := FindArrowX()
			else
				bx := (BarPresent() and RunWidth > 0) ? RunLeft + (RunWidth/2) : -1
			if (bx >= 0)
				{
				if (useArrow)
					MoveHudBarC(bx)
				else
					MoveHudBarSpan(RunLeft, RunWidth)
				if ((dir == "Left" and bx <= FishX) or (dir == "Right" and bx >= FishX))
					{
					HeldFraction := elapsed/ms
					return
					}
				}
			}
		}
}

;====================================================================================================;

ScanRowBar(y, minRun) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, RunLeft, RunWidth
	if (y < 0 or y >= CaptureH)
		return false
	rowOffset := y * CaptureW * 4
	minL := 255
	maxL := 0
	Loop, % CaptureW
		{
		px := NumGet(pCaptureBits + 0, rowOffset + ((A_Index-1)*4), "UInt")
		lum := ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
		if (lum < minL)
			minL := lum
		if (lum > maxL)
			maxL := lum
		}
	if (maxL - minL < 40)
		return false
	thr := minL + (maxL - minL) * 0.55

	maxGap := Round(CaptureW * 0.06)
	if (maxGap < 6)
		maxGap := 6
	bestStart := -1
	bestLen := 0
	spanStart := -1
	spanEnd := -1
	gap := 0
	Loop, % CaptureW
		{
		x := A_Index - 1
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		lum := ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
		if (lum > thr)
			{
			if (spanStart < 0)
				spanStart := x
			spanEnd := x
			gap := 0
			}
		else if (spanStart >= 0)
			{
			gap++
			if (gap > maxGap)
				{
				spanLen := spanEnd - spanStart + 1
				if (spanLen > bestLen)
					{
					bestLen := spanLen
					bestStart := spanStart
					}
				spanStart := -1
				spanEnd := -1
				gap := 0
				}
			}
		}
	if (spanStart >= 0)
		{
		spanLen := spanEnd - spanStart + 1
		if (spanLen > bestLen)
			{
			bestLen := spanLen
			bestStart := spanStart
			}
		}
	if (bestLen < minRun)
		return false
	RunLeft := FishBarLeft + bestStart
	RunWidth := bestLen
	return true
}

CalibrateBarRow(minRun) {
	global CaptureH, CaptureW, BarScanRow, RunLeft, RunWidth, BarRowAgreement
	bestLen := 0
	bestRow := -1
	bestLeft := 0
	rowRuns := {}
	Loop, % CaptureH
		{
		y := A_Index - 1
		if (ScanRowBar(y, minRun))
			{
			rowRuns[y] := {l: RunLeft, w: RunWidth}
			if (RunWidth > bestLen)
				{
				bestLen := RunWidth
				bestRow := y
				bestLeft := RunLeft
				}
			}
		}
	if (bestRow < 0)
		{
		BarRowAgreement := 0
		return false
		}

	bestCentre := bestLeft + bestLen/2
	agree := 0
	for y, r in rowRuns
		{
		c := r.l + r.w/2
		if (Abs(c - bestCentre) <= CaptureW*0.15 and r.w >= bestLen*0.5 and r.w <= bestLen*1.5)
			agree++
		}
	BarRowAgreement := agree
	BarScanRow := bestRow
	RunLeft := bestLeft
	RunWidth := bestLen
	return true
}

ToBGR(rgbHex) {
	v := rgbHex + 0
	return ((v & 0xFF) << 16) | (v & 0xFF00) | ((v >> 16) & 0xFF)
}

ColSpread(x0, x1, fishX) {
	global pCaptureBits, CaptureW, CaptureH
	if (x0 < 0)
		x0 := 0
	if (x1 > CaptureW)
		x1 := CaptureW
	loR := 999999, hiR := -1, loG := 999999, hiG := -1, loB := 999999, hiB := -1
	n := 0
	x := x0
	while (x < x1)
		{
		if (Abs(x - fishX) > 14)
			{
			sR := 0, sG := 0, sB := 0
			y := (CaptureH < 22) ? (CaptureH // 3) : 8
			while (y < ((CaptureH < 22) ? CaptureH : 22))
				{
				px := NumGet(pCaptureBits + 0, (y*CaptureW + x)*4, "UInt")
				sB += px & 0xFF
				sG += (px >> 8) & 0xFF
				sR += (px >> 16) & 0xFF
				y += 2
				}
			if (sR < loR)
				loR := sR
			if (sR > hiR)
				hiR := sR
			if (sG < loG)
				loG := sG
			if (sG > hiG)
				hiG := sG
			if (sB < loB)
				loB := sB
			if (sB > hiB)
				hiB := sB
			n++
			}
		x += 2
		}
	if (n < 10)
		return -1
	return ((hiR - loR) + (hiG - loG) + (hiB - loB)) / 7
}

FrameIsDark() {
	global pCaptureBits, CaptureW, CaptureH
	dark := 0
	n := 0
	y := 0
	while (y < CaptureH)
		{
		off := y * CaptureW * 4
		x := 0
		while (x < CaptureW)
			{
			v := NumGet(pCaptureBits + 0, off + (x*4), "UInt")
			if ((((v & 0xFF) + ((v >> 8) & 0xFF) + ((v >> 16) & 0xFF)) // 3) < 40)
				dark++
			n++
			x += 4
			}
		y += 2
		}
	if (n < 1)
		return false
	return ((dark * 100 // n) >= 85)
}

TqResetAll() {
	global TqHitY, TqRingTop, TqRef
	TqHitY := -1
	TqRingTop := -1
	TqRef := [[89.0, 217.0, 221.0], [119.0, 92.0, 221.0], [227.0, 222.0, 153.0], [211.0, 105.0, 169.0]]
	TqResetFight(0)
}

TqResetFight(t0) {
	global TqV, TqVs, TqNoteD, TqDs, TqNotes, TqLastRing, TqLastLive, TqStarted, TqT0, TqExpired, TqPrevT, TqDl, WindowHeight
	TqV := 0.645 * WindowHeight
	TqVs := []
	TqNoteD := 0.098 * WindowHeight
	TqDs := []
	TqNotes := [[], [], [], []]
	TqLastRing := -1
	TqLastLive := -1
	TqStarted := false
	TqT0 := t0
	TqExpired := false
	TqPrevT := -1
	TqDl := 0
}

TqMedian(arr) {
	w := []
	for i, x in arr
		w.Push(x)
	n := w.Length()
	i := 2
	while (i <= n)
		{
		x := w[i]
		j := i - 1
		while (j >= 1 and w[j] > x)
			{
			w[j + 1] := w[j]
			j--
			}
		w[j + 1] := x
		i++
		}
	if (Mod(n, 2) = 1)
		return w[(n // 2) + 1]
	return (w[n // 2] + w[(n // 2) + 1]) / 2.0
}

TqRing(cx, ByRef cc, ByRef rtop, ByRef pr, ByRef pg, ByRef pb) {
	global pNoteBits, NoteW, NoteH, WindowHeight
	hh := WindowHeight
	expect := NoteH - (hh * 0.0767)
	win := (hh * 0.0625) + (hh * 0.08)
	ya := Round(expect - win)
	yb := Round(expect + win)
	if (ya < 0)
		ya := 0
	if (yb > NoteH - 1)
		yb := NoteH - 1
	smin := hh * 0.004
	smax := (hh * 0.02 > 24) ? hh * 0.02 : 24
	gmin := hh * 0.045
	gmax := (hh * 0.12 > 150) ? hh * 0.12 : 150
	base := pNoteBits + (cx * 4)
	rowb := NoteW * 4
	rs := []
	re := []
	st := -1
	y := ya
	while (y <= yb)
		{
		v := NumGet(base + 0, y * rowb, "UInt")
		cb := v & 0xFF
		cg := (v >> 8) & 0xFF
		cr := (v >> 16) & 0xFF
		mx := (cr > cg) ? ((cr > cb) ? cr : cb) : ((cg > cb) ? cg : cb)
		mn := (cr < cg) ? ((cr < cb) ? cr : cb) : ((cg < cb) ? cg : cb)
		if (mx > 90 and (mx - mn) > 35)
			{
			if (st < 0)
				st := y
			}
		else if (st >= 0)
			{
			rs.Push(st)
			re.Push(y - 1)
			st := -1
			}
		y++
		}
	if (st >= 0)
		{
		rs.Push(st)
		re.Push(yb)
		}
	i := 1
	while (i < rs.Length())
		{
		s1 := rs[i]
		e1 := re[i]
		s2 := rs[i + 1]
		e2 := re[i + 1]
		h1 := e1 - s1 + 1
		h2 := e2 - s2 + 1
		gp := s2 - e1 - 1
		if (h1 >= smin and h1 <= smax and h2 >= smin and h2 <= smax and gp >= gmin and gp <= gmax)
			{
			nd := 0
			y := e1 + 1
			while (y < s2)
				{
				v := NumGet(base + 0, y * rowb, "UInt")
				cb := v & 0xFF
				cg := (v >> 8) & 0xFF
				cr := (v >> 16) & 0xFF
				mx := (cr > cg) ? ((cr > cb) ? cr : cb) : ((cg > cb) ? cg : cb)
				if (mx < 70)
					nd++
				y++
				}
			if (nd * 4 >= gp * 3)
				{
				c0 := (s1 + e2) / 2.0
				if (Abs(c0 - expect) <= hh * 0.0625)
					{
					v := NumGet(base + 0, ((s1 + e1) // 2) * rowb, "UInt")
					pb := v & 0xFF
					pg := (v >> 8) & 0xFF
					pr := (v >> 16) & 0xFF
					cc := c0
					rtop := s1
					return true
					}
				}
			}
		i++
		}
	return false
}

TqRings(ByRef agree) {
	global NoteW, TqHitY, TqRingTop, TqRef
	static fr := [0.1230, 0.3740, 0.6220, 0.8750]
	cs := []
	tops := []
	lns := []
	prs := []
	pgs := []
	pbs := []
	li := 1
	while (li <= 4)
		{
		if (TqRing(Round(NoteW * fr[li]), cc, rtop, pr, pg, pb))
			{
			cs.Push(cc)
			tops.Push(rtop)
			lns.Push(li)
			prs.Push(pr)
			pgs.Push(pg)
			pbs.Push(pb)
			}
		li++
		}
	agree := 0
	n := cs.Length()
	if (n >= 1)
		{
		md := TqMedian(cs)
		ac := []
		at := []
		for i, c0 in cs
			{
			if (Abs(c0 - md) <= 8)
				{
				ac.Push(c0)
				at.Push(tops[i])
				}
			}
		agree := ac.Length()
		if (agree >= 2)
			{
			c0 := TqMedian(ac)
			tp := TqMedian(at)
			TqHitY := (TqHitY < 0) ? c0 : ((TqHitY * 0.8) + (c0 * 0.2))
			TqRingTop := (TqRingTop < 0) ? tp : ((TqRingTop * 0.8) + (tp * 0.2))
			for i, c0 in cs
				{
				if (Abs(c0 - md) <= 8)
					{
					rf := TqRef[lns[i]]
					rf[1] := (rf[1] * 0.8) + (prs[i] * 0.2)
					rf[2] := (rf[2] * 0.8) + (pgs[i] * 0.2)
					rf[3] := (rf[3] * 0.8) + (pbs[i] * 0.2)
					}
				}
			}
		}
	return n
}

TqPurple(r, g, b) {
	return (b > g + 50 and r > g + 20 and b >= r * 0.75 and r >= b * 0.45 and b >= 100)
}

ManiaVisible() {
	global pNoteBits, NoteH
	if (!pNoteBits or NoteH < 120)
		return false
	TqRings(agree)
	return (agree >= 3)
}

ManiaStep(t) {
	global pNoteBits, NoteW, NoteH, WindowHeight, ManiaLead, BarCalculationFailsafe
	global TqHitY, TqRingTop, TqV, TqVs, TqNoteD, TqDs, TqNotes, TqRef, TqLastRing, TqLastLive, TqStarted, TqT0
	global TqExpired, TqPrevT, TqDl
	static fr := [0.1230, 0.3740, 0.6220, 0.8750]
	static keys := ["d", "f", "j", "k"]
	gapT := (TqPrevT >= 0) ? (t - TqPrevT) : 0.0
	TqPrevT := t
	if (gapT > 0 and gapT < 0.1)
		TqDl := (TqDl <= 0) ? gapT : ((TqDl * 0.9) + (gapT * 0.1))
	ts := t
	if (gapT > 0 and gapT < 0.1)
		ts := t - (((gapT < 1.0 / 60) ? gapT : (1.0 / 60)) / 2.0)
	if (!pNoteBits or NoteH < 120)
		{
		if (!TqStarted and (t - TqT0) > BarCalculationFailsafe)
			{
			TqExpired := true
			return false
			}
		return true
		}
	hh := WindowHeight
	nring := TqRings(agree)
	if (!TqStarted)
		{
		if (agree < 3)
			{
			if ((t - TqT0) > BarCalculationFailsafe)
				{
				TqExpired := true
				return false
				}
			return true
			}
		TqStarted := true
		TqLastRing := t
		TqLastLive := t
		if (TqDs.Length() = 0 and TqRingTop >= 0 and TqHitY >= 0)
			TqNoteD := 2.0 * (TqHitY - TqRingTop)
		}
	if (nring >= 1)
		{
		TqLastRing := t
		TqLastLive := t
		}
	hitY := (TqHitY >= 0) ? TqHitY : (NoteH - (hh * 0.0767))
	ringR := (TqRingTop >= 0) ? (hitY - TqRingTop) : (hh * 0.049)
	top := hitY - (1.6 * ringR) - 3
	rd := 2.0 * ringR
	minH := TqNoteD * 0.5
	maxOne := TqNoteD * 1.35
	lead := ManiaLead / 1000.0
	rowb := NoteW * 4
	moving := false
	li := 1
	while (li <= 4)
		{
		base := pNoteBits + (Round(NoteW * fr[li]) * 4)
		rf := TqRef[li]
		sr := rf[1] + rf[2] + rf[3]
		mb := []
		mh := []
		st := -1
		y := 0
		while (y <= NoteH)
			{
			colp := false
			if (y < NoteH)
				{
				v := NumGet(base + 0, y * rowb, "UInt")
				cb := v & 0xFF
				cg := (v >> 8) & 0xFF
				cr := (v >> 16) & 0xFF
				mx := (cr > cg) ? ((cr > cb) ? cr : cb) : ((cg > cb) ? cg : cb)
				mn := (cr < cg) ? ((cr < cb) ? cr : cb) : ((cg < cb) ? cg : cb)
				colp := (mx > 90 and (mx - mn) > 35)
				}
			if (colp)
				{
				if (st < 0)
					st := y
				}
			else if (st >= 0)
				{
				ye := y - 1
				rh := ye - st + 1
				if (ye < top and rh >= minH)
					{
					yc := Floor(ye - (TqNoteD / 2.0))
					if (yc < st)
						yc := st
					v := NumGet(base + 0, yc * rowb, "UInt")
					pb := v & 0xFF
					pg := (v >> 8) & 0xFF
					pr := (v >> 16) & 0xFF
					sp := pr + pg + pb
					if (sp > 0 and sr > 0)
						{
						kr := sp / sr
						dmax := Abs((pr / sp) - (rf[1] / sr))
						dg := Abs((pg / sp) - (rf[2] / sr))
						db := Abs((pb / sp) - (rf[3] / sr))
						if (dg > dmax)
							dmax := dg
						if (db > dmax)
							dmax := db
						if ((kr >= 0.35 and kr <= 0.90 and dmax <= 0.06) or TqPurple(pr, pg, pb))
							{
							if (rh <= maxOne)
								{
								mb.Push(ye + 0.0)
								mh.Push(rh)
								}
							else
								{
								kk := Round(rh / TqNoteD)
								if (kk < 2)
									kk := 2
								j := 0
								while (j < kk)
									{
									mb.Push(ye - ((rh - TqNoteD) * j / (kk - 1)))
									mh.Push(0)
									j++
									}
								}
							}
						}
					}
				st := -1
				}
			y++
			}
		i := 2
		while (i <= mb.Length())
			{
			xb := mb[i]
			xh := mh[i]
			j := i - 1
			while (j >= 1 and mb[j] < xb)
				{
				mb[j + 1] := mb[j]
				mh[j + 1] := mh[j]
				j--
				}
			mb[j + 1] := xb
			mh[j + 1] := xh
			i++
			}
		lane := TqNotes[li]
		used := []
		Loop, % lane.Length()
			used.Push(false)
		for mi, bot in mb
			{
			rh := mh[mi]
			best := 0
			bd := 1000000000.0
			i := 1
			while (i <= lane.Length())
				{
				if (!used[i])
					{
					nt := lane[i]
					dtt := t - nt.tb
					d := Abs(bot - (nt.bot + (TqV * dtt)))
					win := hh * 0.012
					if (0.3 * TqV * dtt > win)
						win := 0.3 * TqV * dtt
					win += TqV / 30.0
					if (d <= win and d < bd)
						{
						best := i
						bd := d
						}
					}
				i++
				}
			if (!best)
				{
				anc := (rh > 0 and rh >= rd * 0.85 and rh <= rd * 1.15)
				lane.Push({bot: bot, tb: ts, ta: ts + ((hitY + (TqNoteD / 2.0) - bot) / TqV), n: 1, nm: 0, fired: false, b0: (anc ? bot : -1.0), t0: (anc ? ts : -1.0)})
				used.Push(true)
				continue
				}
			used[best] := true
			nt := lane[best]
			dt := ts - nt.tb
			disp := bot - nt.bot
			nt.n := nt.n + 1
			if (Abs(disp) < 1)
				continue
			single := (rh > 0 and rh >= rd * 0.85 and rh <= rd * 1.15)
			if (single and nt.t0 < 0)
				{
				nt.b0 := bot
				nt.t0 := ts
				}
			else if (single and ts - nt.t0 >= 0.25)
				{
				vs := (bot - nt.b0) / (ts - nt.t0)
				if (vs >= hh * 0.25 and vs <= hh * 1.6)
					{
					TqVs.Push(vs)
					if (TqVs.Length() > 25)
						TqVs.RemoveAt(1)
					if (TqVs.Length() >= 3)
						TqV := TqMedian(TqVs)
					}
				}
			if (rh > 0 and rh >= rd * 0.6 and rh <= rd * 1.4)
				{
				TqDs.Push(rh)
				if (TqDs.Length() > 25)
					TqDs.RemoveAt(1)
				if (TqDs.Length() >= 5)
					TqNoteD := TqMedian(TqDs)
				}
			if (dt > 0.004 and disp >= (0.7 * TqV * dt) - 3 and disp <= (1.3 * TqV * dt) + 3)
				{
				nt.nm := nt.nm + 1
				if (nt.nm >= 2)
					moving := true
				}
			nt.bot := bot
			nt.tb := ts
			if (!nt.fired)
				nt.ta := ts + ((hitY + (TqNoteD / 2.0) - bot) / TqV)
			}
		i := 2
		while (i <= lane.Length())
			{
			x := lane[i]
			j := i - 1
			while (j >= 1 and lane[j].ta > x.ta)
				{
				lane[j + 1] := lane[j]
				j--
				}
			lane[j + 1] := x
			i++
			}
		half := (TqDl < 0.05) ? (TqDl / 2.0) : 0.0
		for i, nt in lane
			{
			if (!nt.fired and nt.nm >= 2 and t + half >= nt.ta - lead)
				{
				send % "{" . keys[li] . "}"
				nt.fired := true
				break
				}
			}
		kept := []
		for i, nt in lane
			{
			if (nt.ta < t - 0.30)
				continue
			if (!nt.fired and (t - nt.tb) > 0.15)
				{
				pp := nt.bot + (TqV * (t - nt.tb))
				if (pp < top)
					{
					dup := false
					for j, o in lane
						{
						if (o.tb = ts and Abs(pp - o.bot) <= TqNoteD)
							{
							dup := true
							break
							}
						}
					if (dup)
						continue
					}
				}
			kept.Push(nt)
			}
		TqNotes[li] := kept
		li++
		}
	if (moving)
		TqLastLive := t
	return ((t - TqLastLive) <= 0.5 and (t - TqLastRing) <= 2.0)
}

NoiseHasMark(arr, n, x, tol) {
	i := 1
	while (i <= n)
		{
		if (Abs(arr[i] - x) <= tol)
			return true
		i++
		}
	return false
}

NoiseScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, QpcFreq, FishColor, FishBarColorTolerance
	global NoiseBarL, NoiseBarW, NoiseFishX, NoiseFound, NoiseScanned, NoiseFishFresh
	global NoisePrevC, NoisePrevT, NoiseFishPrev, NoiseFishT, NoiseStillX, NoiseStillC, NoiseWCal, NoiseJumpN
	global NoiseWCnt, NoiseWVote, NoiseZOK, NoiseZoneTgt
	global NoiseLastD, NoiseOscN, NoiseVelC
	global NoiseRowOff
	global NoiseCoastN
	global NoiseEHist
	global NoiseJumpHold
	global NoiseRate, NoiseRateT, NoiseN6, NoiseN8, NoiseN15, NoiseN45
	global NoiseAltW, NoiseAltN, NoiseZSeenT
	global NoiseBandT, NoiseBandB, NoiseRlW, NoiseRlN
	if (NoiseScanned)
		return NoiseFound
	NoiseScanned := true
	DllCall("QueryPerformanceCounter", "Int64*", rtnow)
	rdt := (NoiseRateT > 0) ? ((rtnow - NoiseRateT) / QpcFreq) : 0
	NoiseRateT := rtnow
	if (rdt > 0 and rdt < 0.25)
		{
		rnow := rdt / 0.040
		if (rnow < 1)
			rnow := 1
		NoiseRate := (NoiseRate * 0.8) + (rnow * 0.2)
		}
	if (NoiseRate < 1)
		NoiseRate := 1
	NoiseN6 := (NoiseRate <= 1) ? 6 : Max(2, Round(6 / NoiseRate))
	NoiseN8 := (NoiseRate <= 1) ? 8 : Max(2, Round(8 / NoiseRate))
	NoiseN15 := (NoiseRate <= 1) ? 15 : Max(3, Round(15 / NoiseRate))
	NoiseN45 := (NoiseRate <= 1) ? 45 : Max(8, Round(45 / NoiseRate))
	NoiseFound := false
	NoiseFishX := -1
	NoiseFishFresh := false
	y0 := Round(CaptureH * 0.10)
	y1 := Round(CaptureH * 0.35)
	if (y1 - y0 < 2)
		{
		y0 := 0
		y1 := CaptureH
		}
	step := 1
	ncol := CaptureW // step
	if (ncol < 40)
		return false
	bmWmax := Round(CaptureW * 0.008) + 2
	bvStep := CaptureH // 13
	if (bvStep < 1)
		bvStep := 1
	bvTot := 0
	byq := 0
	while (byq < CaptureH)
		{
		bvTot++
		byq += bvStep
		}
	bvNeed := Round(bvTot * 0.60)
	if (bvNeed < 3)
		bvNeed := 3
	bmN := 0
	bmX := []
	if (NoiseBandT > -99)
		{
		bT0 := pCaptureBits + (NoiseBandT * CaptureW * 4)
		bT2 := bT0 + (2 * CaptureW * 4)
		bB0 := pCaptureBits + ((NoiseBandB - 4) * CaptureW * 4)
		bRow := CaptureW * 4
		brun := -1
		bx := 0
		while (bx <= CaptureW)
			{
			bIsEdge := false
			if (bx < CaptureW)
				{
				v := NumGet(bT2 + 0, bx*4, "UInt")
				if (!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
					{
					tMiss := 0
					bMiss := 0
					bk := 0
					while (bk < 5)
						{
						if (bk != 2)
							{
							v := NumGet(bT0 + 0, (bk*bRow) + bx*4, "UInt")
							if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
								tMiss++
							}
						v := NumGet(bB0 + 0, (bk*bRow) + bx*4, "UInt")
						if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
							bMiss++
						if (tMiss > 1 or bMiss > 1)
							break
						bk++
						}
					if (bk >= 5)
						bIsEdge := true
					}
				}
			if (bIsEdge)
				{
				if (brun < 0)
					brun := bx
				}
			else if (brun >= 0)
				{
				if (bx - brun <= bmWmax)
					{
					bmN++
					bmX[bmN] := (brun + bx - 1) // 2
					}
				brun := -1
				}
			bx++
			}
		}
	if (bmN = 0)
		{
		brun := -1
		bx := 0
		while (bx <= CaptureW)
			{
			bIsEdge := false
			if (bx < CaptureW)
				{
				bHit := 0
				bSeen := 0
				by2 := 0
				while (by2 < CaptureH)
					{
					v := NumGet(pCaptureBits + 0, (by2*CaptureW + bx)*4, "UInt")
					bSeen++
					if (!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
						bHit++
					if ((bHit + (bvTot - bSeen)) < bvNeed)
						break
					by2 += bvStep
					}
				if (bHit >= bvNeed)
					bIsEdge := true
				}
			if (bIsEdge)
				{
				if (brun < 0)
					brun := bx
				}
			else if (brun >= 0)
				{
				if (bx - brun <= bmWmax)
					{
					bmN++
					bmX[bmN] := (brun + bx - 1) // 2
					}
				brun := -1
				}
			bx++
			}
		if (bmN >= 2)
			{
			lmid := CaptureH // 2
			lPT := -99
			lPB := -99
			lHit := false
			li := 1
			while (li <= bmN and !lHit)
				{
				lx := bmX[li]
				v := NumGet(pCaptureBits + 0, (lmid*CaptureW + lx)*4, "UInt")
				if (!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
					{
					lt := lmid
					while (lt > -18)
						{
						v := NumGet(pCaptureBits + ((lt - 1)*CaptureW + lx)*4, 0, "UInt")
						if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
							break
						lt--
						}
					lb := lmid
					while (lb < CaptureH + 19)
						{
						v := NumGet(pCaptureBits + ((lb + 1)*CaptureW + lx)*4, 0, "UInt")
						if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
							break
						lb++
						}
					if (lt > -18 and lt < 0 and lb >= CaptureH and lb < CaptureH + 19 and (lb - lt + 1) >= CaptureH * 1.2 and (lb - lt + 1) <= CaptureH * 1.7)
						{
						if (lPT > -99 and Abs(lt - lPT) <= 1 and Abs(lb - lPB) <= 1)
							{
							NoiseBandT := Max(lt, lPT)
							NoiseBandB := Min(lb, lPB)
							lHit := true
							}
						lPT := lt
						lPB := lb
						}
					}
				li++
				}
			}
		}
	NoiseEHist.Push(bmX.Clone())
	if (NoiseEHist.Length() > 20)
		NoiseEHist.RemoveAt(1)
	if (bmN >= 2 and NoiseEHist.Length() >= 20)
		{
		sN := 0
		sKeep := []
		si := 1
		while (si <= bmN)
			{
			sx := bmX[si]
			scnt := 0
			sh := 1
			while (sh <= NoiseEHist.Length())
				{
				harr := NoiseEHist[sh]
				sj := 1
				while (sj <= harr.Length())
					{
					if (Abs(harr[sj] - sx) <= 2)
						{
						scnt++
						break
						}
					sj++
					}
				sh++
				}
			if (scnt < 18 or (NoisePrevC >= 0 and NoiseWCal >= 40 and (Abs(sx - (NoisePrevC - (NoiseWCal / 2))) <= 4 or Abs(sx - (NoisePrevC + (NoiseWCal / 2))) <= 4)))
				{
				sN++
				sKeep[sN] := sx
				}
			si++
			}
		if (sN >= 2)
			{
			bmN := sN
			bmX := sKeep
			}
		}
	if (bmN >= 2 and !NoiseZOK and bmX[1] > 3 and bmX[bmN] < CaptureW - 4)
		{
		wobs := bmX[bmN] - bmX[1]
		if (wobs >= CaptureW * 0.15 and wobs <= CaptureW * 0.45)
			{
			wq := (wobs // 4) * 4
			if (!NoiseWCnt.HasKey(wq))
				NoiseWCnt[wq] := 0
			if (NoiseWCnt[wq] < 40)
				NoiseWCnt[wq] := NoiseWCnt[wq] + 1
			if (NoiseWCal >= 40 and wq != NoiseWCal)
				{
				if (!NoiseWCnt.HasKey(NoiseWCal))
					NoiseWCnt[NoiseWCal] := 0
				if (NoiseWCnt[NoiseWCal] > 0)
					NoiseWCnt[NoiseWCal] := NoiseWCnt[NoiseWCal] - 1
				}
			wLead := 0
			if (NoiseWCal >= 40 and NoiseWCnt.HasKey(NoiseWCal))
				wLead := NoiseWCnt[NoiseWCal]
			if (NoiseWCal < 40 or NoiseWCnt[wq] > wLead)
				{
				NoiseWVote := NoiseWCnt[wq]
				NoiseWCal := wq
				}
			}
		}
	wexp := (NoiseWCal >= 40) ? NoiseWCal : (CaptureW * 0.303)
	wtol := Round(CaptureW * 0.016)
	if (wtol < 10)
		wtol := 10
	pairOK := false
	pi := 1
	while (pi <= bmN)
		{
		pj := pi + 1
		while (pj <= bmN)
			{
			if (Abs((bmX[pj] - bmX[pi]) - wexp) <= wtol)
				pairOK := true
			pj++
			}
		pi++
		}
	arwOK := false
	if (!pairOK)
		{
		ay0 := Round(CaptureH * 0.46)
		ay1 := Round(CaptureH * 0.87)
		if (ay1 <= ay0 + 1)
			{
			ay0 := CaptureH // 2
			ay1 := ay0 + 2
			}
		acnt := []
		astep := 2
		ax := 0
		while (ax < CaptureW)
			{
			cc := 0
			ay := ay0
			while (ay < ay1)
				{
				v := NumGet(pCaptureBits + 0, (ay*CaptureW + ax)*4, "UInt")
				if (((((v & 0xFF) + ((v >> 8) & 0xFF) + ((v >> 16) & 0xFF)) // 3)) <= 12)
					cc++
				ay += 4
				}
			acnt[ax] := cc
			ax += astep
			}
		awmin := Round(CaptureW * 0.019)
		awmax := Round(CaptureW * 0.09)
		bestAw := 0
		bestAa := -1
		bestAb := -1
		ra := -1
		ax := 0
		while (ax <= CaptureW)
			{
			isa := (ax < CaptureW and acnt[ax] >= 1)
			if (isa)
				{
				if (ra < 0)
					ra := ax
				}
			else if (ra >= 0)
				{
			rb := ax - astep
				aw := rb - ra + 1
				if (aw >= awmin and aw <= awmax and aw > bestAw)
					{
					bestAw := aw
					bestAa := ra
					bestAb := rb
					}
				ra := -1
				}
		ax += astep
			}
		if (bestAw > 0)
			{
			th := bestAw // 3
			if (th < 1)
				th := 1
			lsum := 0
			rsum := 0
			kk := 0
			while (kk < th)
				{
				lsum += acnt[bestAa + kk]
				rsum += acnt[bestAb - kk]
				kk++
				}
		useW := (NoiseWCal >= 40) ? NoiseWCal : (CaptureW * 0.30)
			ains := Round(useW * 0.125)
			acx := (bestAa + bestAb) // 2
			if (rsum > lsum)
				{
				barRp := acx + ains
			barLp := barRp - Round(useW)
				}
			else
				{
				barLp := acx - ains
			barRp := barLp + Round(useW)
				}
			if (barLp < 0)
			barLp := barLp
			if (barRp > CaptureW - 1)
			barRp := barRp
			if (barRp - barLp >= 40)
				{
				arwL := barLp
				arwR := barRp
				arwOK := true
				}
			}
		}
	wexp := (NoiseWCal >= 40) ? NoiseWCal : (CaptureW * 0.303)
	wtol := Round(CaptureW * 0.016)
	if (wtol < 10)
		wtol := 10
	nrun := 0
	if (!pairOK and !arwOK)
		{
		lum := []
		gex := []
		hist := []
		bi := 0
		while (bi < 64)
			{
			hist[bi] := 0
			bi++
			}
		i := 0
		while (i < ncol)
			{
			x := i * step
			s := 0
			sg := 0
			smx := 0
			c := 0
			y := y0
			while (y < y1)
				{
				v := NumGet(pCaptureBits + 0, (y*CaptureW + x)*4, "UInt")
				pb := (v & 0xFF)
				pg := ((v >> 8) & 0xFF)
				pr := ((v >> 16) & 0xFF)
				s += (pr + pg + pb) // 3
				sg += pg
				smx += (pr > pb) ? pr : pb
				c++
				y += 2
				}
			if (c < 1)
				c := 1
			lv := s // c
			lum[i] := lv
			gex[i] := (sg - smx) // c
			bi := lv // 4
			if (bi > 63)
				bi := 63
			if (bi < 0)
				bi := 0
			hist[bi] := hist[bi] + 1
			i++
			}
		need := Round(ncol * 0.20)
		acc := 0
		bg := 0
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				bg := bi * 4
				break
				}
			bi++
			}
		need := Round(ncol * 0.98)
		acc := 0
		pk := 255
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				pk := bi * 4
				break
				}
			bi++
			}
		if (pk - bg < 40)
			return false
		thr := bg + ((pk - bg) * 0.45)
		gapmax := Round(ncol * 0.025)
		if (gapmax < 5)
			gapmax := 5
		minw := Round(ncol * 0.22)
		if (minw < 20)
			minw := 20
		rs := -1
		re := -1
		gap := 0
		nrun := 0
		rA := []
		rB := []
		i := 0
		while (i <= ncol)
			{
			isb := (i < ncol and lum[i] >= thr)
			if (isb)
				{
				if (rs < 0)
					rs := i
				re := i
				gap := 0
				}
			else if (rs >= 0)
				{
				gap++
				if (gap > gapmax or i = ncol)
					{
					gsum := 0
					gn := 0
					gi := rs
					while (gi <= re)
						{
						gsum += gex[gi]
						gn++
						gi++
						}
					if (gn < 1)
						gn := 1
					if (re - rs + 1 >= minw and (gsum // gn) >= 25)
						{
						nrun++
						rA[nrun] := rs
						rB[nrun] := re
						}
					rs := -1
					gap := 0
					}
				}
			i++
			}
		}
	gotBar := (nrun >= 1)
	bs := -99999
	be := -1
	DllCall("QueryPerformanceCounter", "Int64*", tnow)
	fresh := (NoisePrevT > 0 and ((tnow - NoisePrevT) / QpcFreq) < 0.6)
	if (gotBar)
		{
		bestI := 0
		bestSc := -999999
		k := 1
		while (k <= nrun)
			{
			w := rB[k] - rA[k] + 1
			cx := ((rA[k] + rB[k]) * step) // 2
			sc := w
			if (fresh)
				sc := w - (Abs(cx - NoisePrevC) // step)
			if (sc > bestSc)
				{
				bestSc := sc
				bestI := k
				}
			k++
			}
		bs := rA[bestI]
		be := rB[bestI]
		if (NoiseWCal < 40 and rA[bestI] > 0 and rB[bestI] < ncol - 1)
			NoiseWCal := (be - bs + 1) * step
		}
	bdL := 0
	bdOK := false
	bdR := -1
	bdBest := 999999
	bdPair := false
	bdFresh := (NoisePrevT > 0 and NoisePrevC >= 0 and ((tnow - NoisePrevT) / QpcFreq) < 0.8)
	arwC := arwOK ? ((arwL + arwR) // 2) : -99999
	mirL := NoisePrevC - (wexp / 2)
	mirR := NoisePrevC + (wexp / 2)
	mirTol := Round(CaptureW * 0.03)
	if (mirTol < 12)
		mirTol := 12
	bi2 := 1
	while (bi2 <= bmN)
		{
		bj := bi2 + 1
		while (bj <= bmN)
			{
			sep := bmX[bj] - bmX[bi2]
			isMirror := (bdFresh and ((Abs(bmX[bj] - mirL) <= mirTol and bmX[bi2] < mirL - (wexp / 2))
				or (Abs(bmX[bi2] - mirR) <= mirTol and bmX[bj] > mirR + (wexp / 2))))
			if (Abs(sep - wexp) <= wtol and !isMirror)
				{
				cc := (bmX[bi2] + bmX[bj]) // 2
				scr := Abs(sep - wexp) * 2
				if (bdFresh)
					scr += Abs(cc - NoisePrevC)
				else if (arwOK)
					scr += Abs(cc - arwC)
				if (scr < bdBest)
					{
					bdBest := scr
					bdL := bmX[bi2]
					bdOK := true
					bdR := bmX[bj]
					bdPair := true
					}
				}
			bj++
			}
		bi2++
		}
	if (bdPair and arwOK and !bdFresh and Abs(((bdL + bdR) // 2) - arwC) > Round(CaptureW * 0.07))
		{
		bdOK := false
		bdPair := false
		}
	DllCall("QueryPerformanceCounter", "Int64*", altNow)
	if (NoiseZOK)
		NoiseZSeenT := altNow
	altWin := (!NoiseZOK and NoiseZSeenT > 0 and ((altNow - NoiseZSeenT) / QpcFreq) < 4.0)
	if (bdPair or !altWin)
		NoiseAltN := 0
	else if (NoiseWCal >= 40)
		{
		altBest := -1
		altL := 0
		altR := 0
		ai := 1
		while (ai <= bmN)
			{
			aj := ai + 1
			while (aj <= bmN)
				{
				asep := bmX[aj] - bmX[ai]
				arat := (asep * 100) // NoiseWCal
				if ((arat >= 50 and arat <= 92) or (arat >= 108 and arat <= 150))
					{
					if (NoiseAltW > 0)
						asc := Abs(asep - NoiseAltW)
					else if (NoiseFishPrev >= 0)
						asc := Abs(((bmX[ai] + bmX[aj]) // 2) - NoiseFishPrev)
					else
						asc := 0
					if (altBest < 0 or asc < altBest)
						{
						altBest := asc
						altL := bmX[ai]
						altR := bmX[aj]
						}
					}
				aj++
				}
			ai++
			}
		if (altBest < 0)
			{
			NoiseAltN := 0
			NoiseAltW := 0
			}
		else if (NoiseAltW > 0 and Abs((altR - altL) - NoiseAltW) <= 4)
			NoiseAltN := NoiseAltN + 1
		else
			{
			NoiseAltW := altR - altL
			NoiseAltN := 1
			}
		if (NoiseAltN >= 3)
			{
			NoiseWCal := altR - altL
			NoiseWCnt := {}
			NoiseWVote := 0
			NoiseJumpN := 0
			NoiseOscN := 0
			NoiseCoastN := 0
			NoiseAltN := 0
			NoiseAltW := 0
			bdL := altL
			bdR := altR
			bdOK := true
			bdPair := true
			bdFresh := false
			wexp := NoiseWCal
			}
		}
	if (!bdPair and NoiseWCal >= 40 and bmN >= 2)
		{
		rlN := 0
		ri := 1
		while (ri < bmN)
			{
			rj := ri + 1
			while (rj <= bmN)
				{
				rsep := bmX[rj] - bmX[ri]
				if (rsep >= CaptureW * 0.15 and rsep <= CaptureW * 0.45)
					{
					rlN++
					rlL := bmX[ri]
					rlR := bmX[rj]
					}
				rj++
				}
			ri++
			}
		if (rlN = 1 and Abs((rlR - rlL) - NoiseWCal) > wtol and (NoisePrevC < 0 or Abs(((rlL + rlR) // 2) - NoisePrevC) <= CaptureW * 0.3))
			{
			if (NoiseRlW > 0 and Abs((rlR - rlL) - NoiseRlW) <= 3)
				NoiseRlN := NoiseRlN + 1
			else
				{
				NoiseRlW := rlR - rlL
				NoiseRlN := 1
				}
			if (NoiseRlN >= 2)
				{
				NoiseWCal := rlR - rlL
				NoiseWCnt := {}
				NoiseWVote := 0
				NoiseJumpN := 0
				NoiseOscN := 0
				NoiseCoastN := 0
				NoiseRlN := 0
				NoiseRlW := 0
				bdL := rlL
				bdR := rlR
				bdOK := true
				bdPair := true
				bdFresh := false
				wexp := NoiseWCal
				}
			}
		else
			NoiseRlN := 0
		}
	if (!bdOK)
		{
		bi2 := 1
		while (bi2 <= bmN)
			{
			cLx := bmX[bi2]
			cRx := Round(bmX[bi2] + wexp)
			cc := (cLx + cRx) // 2
			scr := bdFresh ? Abs(cc - NoisePrevC) : (arwOK ? Abs(cc - arwC) : 40)
			if (cRx < CaptureW - 3 and !(NoiseFishPrev >= 0 and Abs(cRx - NoiseFishPrev) <= 12) and !NoiseHasMark(bmX, bmN, cRx, wtol))
				scr += CaptureW // 2
			if (NoiseWCal >= 40 and cRx > CaptureW + (CaptureW // 60))
				scr += CaptureW
			if (scr < bdBest)
				{
				bdBest := scr
				bdL := cLx
				bdOK := true
				bdR := cRx
				}
			cRx := bmX[bi2]
			cLx := Round(bmX[bi2] - wexp)
			cc := (cLx + cRx) // 2
			scr := bdFresh ? Abs(cc - NoisePrevC) : (arwOK ? Abs(cc - arwC) : 60)
			if (cLx > 2 and !(NoiseFishPrev >= 0 and Abs(cLx - NoiseFishPrev) <= 12) and !NoiseHasMark(bmX, bmN, cLx, wtol))
				scr += CaptureW // 2
			if (NoiseWCal >= 40 and cLx < -(CaptureW // 60))
				scr += CaptureW
			if (scr < bdBest)
				{
				bdBest := scr
				bdL := cLx
				bdOK := true
				bdR := cRx
				}
			bi2++
			}
		}
	if (!bdOK and arwOK and NoiseWCal >= 40)
		{
		bdL := arwL
		bdOK := true
		bdR := arwR
		}
	if (bdOK and bdFresh and NoiseCoastN = 0)
		{
		ccF := (bdL + bdR) // 2
		if (Abs(ccF - NoisePrevC) > Round(CaptureW * 0.12 * NoiseRate))
			{
			NoiseJumpN := NoiseJumpN + 1
			if (NoiseJumpN < NoiseN8)
				bdOK := false
			else
				NoiseJumpN := 0
			}
		}
	if (bdOK and bdR - bdL >= 40)
		{
		bs := bdL // step
		be := bdR // step
		gotBar := true
		if (bdPair and NoiseWVote < 2)
			{
			if (NoiseWCal < 40)
				NoiseWCal := bdR - bdL
			else if (Abs((bdR - bdL) - NoiseWCal) <= NoiseWCal * 0.10)
				NoiseWCal := (NoiseWCal * 0.90) + ((bdR - bdL) * 0.10)
			}
		}
	if (gotBar and bs >= 0 and bdFresh and NoiseCoastN = 0)
		{
		ccF2 := ((bs + be) * step) // 2
		if (Abs(ccF2 - NoisePrevC) > Round(CaptureW * 0.12 * NoiseRate))
			{
			NoiseJumpN := NoiseJumpN + 1
			if (NoiseJumpN < NoiseN15)
				gotBar := false
			else
				NoiseJumpN := 0
			}
		else
			NoiseJumpN := 0
		}
	if (gotBar and bdFresh and NoisePrevC >= 0)
		{
		ccF3 := ((bs + be) * step) // 2
		dNow := ccF3 - NoisePrevC
		if (NoiseLastD != 0 and (dNow * NoiseLastD) < 0 and Abs(dNow) > Round(CaptureW * 0.02 * NoiseRate) and NoiseOscN < NoiseN6)
			{
			NoiseOscN := NoiseOscN + 1
			oHalf := (be - bs) // 2
			bs := (NoisePrevC // step) - oHalf
			be := (NoisePrevC // step) + oHalf
			}
		else
			{
			NoiseOscN := 0
			NoiseLastD := dNow
			NoiseVelC := ((NoiseVelC * 6) + (dNow * 4)) // 10
			}
		}
	if (gotBar and NoiseWCal >= 40)
		{
		cwid := (be - bs + 1) * step
		if (Abs(cwid - NoiseWCal) > (NoiseWCal // 4))
			gotBar := false
		}
	if (!gotBar)
		{
		if (NoisePrevC >= 0 and NoiseWCal >= 40 and NoiseCoastN < NoiseN6)
			{
			NoiseCoastN := NoiseCoastN + 1
			cstep := NoiseVelC
			cmax := Round(CaptureW * 0.035 * NoiseRate)
			if (cmax < 25)
				cmax := 25
			if (cstep > cmax)
				cstep := cmax
			if (cstep < -cmax)
				cstep := -cmax
			predC := NoisePrevC + cstep
			if (predC < 0)
				predC := 0
			if (predC > CaptureW)
				predC := CaptureW
			bs := Round((predC - (NoiseWCal / 2)) / step)
			be := Round((predC + (NoiseWCal / 2)) / step)
			gotBar := true
			}
		else
			return false
		}
	else
		NoiseCoastN := 0
	NoiseBarL := FishBarLeft + (bs * step)
	NoiseBarW := (be - bs + 1) * step
	NoiseFound := true
	NoisePrevC := ((bs + be) * step) // 2
	NoisePrevT := tnow
	if (Abs(NoisePrevC - NoiseStillX) <= 2)
		NoiseStillC := NoiseStillC + 1
	else
		{
		NoiseStillC := 0
		NoiseStillX := NoisePrevC
		}
	if (NoiseStillC >= NoiseN45)
		{
		NoisePrevT := 0
		NoiseStillC := 0
		}
	fbgr := ToBGR(ColMain(FishColor))
	ftB := (fbgr >> 16) & 0xFF
	ftG := (fbgr >> 8) & 0xFF
	ftR := fbgr & 0xFF
	ftol := FishBarColorTolerance
	if (ftol < 6)
		ftol := 6
	frow := CaptureH // 2
	fneed := (NoiseZOK or NoiseZoneTgt >= 0) ? 3 : 4
	fwmax := Round(CaptureW * 0.028)
	if (fwmax < 8)
		fwmax := 8
	edgeM := Round(CaptureW * 0.016)
	if (edgeM < 10)
		edgeM := 10
	barA := bs * step
	barB := be * step
	nf := 0
	fX := []
	fx2 := 0
	while (fx2 < CaptureW)
		{
		pv := NumGet(pCaptureBits + 0, (frow*CaptureW + fx2)*4, "UInt")
		if ((Abs((pv & 0xFF) - ftB) <= ftol and Abs(((pv >> 8) & 0xFF) - ftG) <= ftol and Abs(((pv >> 16) & 0xFF) - ftR) <= ftol) or (((pv >> 8) & 0xFF) >= 34 and ((pv >> 8) & 0xFF) <= 104 and ((pv >> 16) & 0xFF) <= 52 and (pv & 0xFF) <= 76 and ((pv >> 8) & 0xFF) >= ((pv >> 16) & 0xFF) + 10 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 4 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) >= 14 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) <= 74))
			{
			fst := fx2
			while (fx2 < CaptureW)
				{
				pv := NumGet(pCaptureBits + 0, (frow*CaptureW + fx2)*4, "UInt")
				if !((Abs((pv & 0xFF) - ftB) <= ftol and Abs(((pv >> 8) & 0xFF) - ftG) <= ftol and Abs(((pv >> 16) & 0xFF) - ftR) <= ftol) or (((pv >> 8) & 0xFF) >= 34 and ((pv >> 8) & 0xFF) <= 104 and ((pv >> 16) & 0xFF) <= 52 and (pv & 0xFF) <= 76 and ((pv >> 8) & 0xFF) >= ((pv >> 16) & 0xFF) + 10 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 4 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) >= 14 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) <= 74))
					break
				fx2++
				}
			fw := fx2 - fst
			if (fw >= 3 and fw <= fwmax)
				{
				fcx := fst + (fw // 2)
				fhits := 0
				fk := 1
				while (fk <= 5)
					{
					fy := Floor(CaptureH * (fk*2 - 1) / 10)
					if (fy >= CaptureH)
						fy := CaptureH - 1
					pv := NumGet(pCaptureBits + 0, (fy*CaptureW + fcx)*4, "UInt")
					if (NoiseIsCore(pv, ftB, ftG, ftR, ftol))
						fhits++
					fk++
					}
				if (fhits >= fneed and Abs(fcx - barA) > edgeM and Abs(fcx - barB) > edgeM)
					{
					gSum := 0
					gN := 0
					fy := 2
					while (fy < CaptureH - 2)
						{
						v := NumGet(pCaptureBits + 0, (fy*CaptureW + fcx)*4, "UInt")
						gSum += ((v >> 8) & 0xFF)
						gN++
						fy++
						}
					if (gN < 1)
						gN := 1
					ownG := gSum // gN
					maxL := 0
					maxR := 0
					kk := 1
					while (kk <= 4)
						{
						xx := fst - kk
						if (xx < 0)
							xx := 0
						v := NumGet(pCaptureBits + 0, (frow*CaptureW + xx)*4, "UInt")
						gv := (v >> 8) & 0xFF
						if (gv > maxL)
							maxL := gv
						xx := fx2 - 1 + kk
						if (xx > CaptureW - 1)
							xx := CaptureW - 1
						v := NumGet(pCaptureBits + 0, (frow*CaptureW + xx)*4, "UInt")
						gv := (v >> 8) & 0xFF
						if (gv > maxR)
							maxR := gv
						kk++
						}
					if (maxL >= ownG + 80 and maxR >= ownG + 80)
						{
						nf++
						fX[nf] := fcx
						}
					}
				}
			}
		else
			fx2++
		}
	if (NoiseBandT > -99)
		{
		pTop := Max(-17, NoiseBandT - Round(CaptureH * 0.41) + 1)
		pBot := NoiseBandT - 2
		if (pBot - pTop >= 4)
			{
			pr0 := pCaptureBits + (((pTop + pBot) // 2) * CaptureW * 4)
			pr1 := pCaptureBits + ((pTop + 1) * CaptureW * 4)
			pr2 := pCaptureBits + ((pBot - 1) * CaptureW * 4)
			nc := 0
			cX := []
			fk := 1
			while (fk <= nf)
				{
				pv := NumGet(pr0 + 0, fX[fk]*4, "UInt")
				if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
					{
					pv := NumGet(pr1 + 0, fX[fk]*4, "UInt")
					if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
						{
						pv := NumGet(pr2 + 0, fX[fk]*4, "UInt")
						if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
							{
							nc++
							cX[nc] := fX[fk]
							}
						}
					}
				fk++
				}
			if (nc >= 1)
				{
				fX := cX
				nf := nc
				}
			else
				{
				mN := 0
				mX := []
				mx2 := 0
				while (mx2 < CaptureW)
					{
					pv := NumGet(pr0 + 0, mx2*4, "UInt")
					if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
						{
						mst := mx2
						while (mx2 < CaptureW)
							{
							pv := NumGet(pr0 + 0, mx2*4, "UInt")
							if !((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
								break
							mx2++
							}
						mw := mx2 - mst
						if (mw >= 3 and mw <= Max(8, Round(CaptureW * 0.014)))
							{
							mcx := mst + (mw // 2)
							pv := NumGet(pr1 + 0, mcx*4, "UInt")
							if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
								{
								pv := NumGet(pr2 + 0, mcx*4, "UInt")
								if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
									{
									ownG := (NumGet(pr0 + 0, mcx*4, "UInt") >> 8) & 0xFF
									maxL := 0
									maxR := 0
									kk := 1
									while (kk <= 4)
										{
										xx := Max(0, mst - kk)
										gv := (NumGet(pr0 + 0, xx*4, "UInt") >> 8) & 0xFF
										if (gv > maxL)
											maxL := gv
										xx := Min(CaptureW - 1, mx2 - 1 + kk)
										gv := (NumGet(pr0 + 0, xx*4, "UInt") >> 8) & 0xFF
										if (gv > maxR)
											maxR := gv
										kk++
										}
									if (maxL >= ownG + 80 and maxR >= ownG + 80)
										{
										mN++
										mX[mN] := mcx
										}
									}
								}
							}
						}
					else
						mx2++
					}
				if (mN >= 1)
					{
					fX := mX
					nf := mN
					}
				}
			}
		}
	if (nf < 1)
		{
		if (NoiseFishT > 0 and NoiseFishPrev >= 0 and ((tnow - NoiseFishT) / QpcFreq) < 1.2)
			NoiseFishX := FishBarLeft + NoiseFishPrev
		return true
		}
	fpick := fX[1]
	if (NoiseFishT > 0 and NoiseFishPrev >= 0 and ((tnow - NoiseFishT) / QpcFreq) < 0.35)
		{
		fjmax := Round(CaptureW * 0.10)
		if (fjmax < 100)
			fjmax := 100
		fnear := false
		fk2 := 1
		while (fk2 <= nf)
			{
			if (Abs(fX[fk2] - NoiseFishPrev) <= fjmax)
				fnear := true
			fk2++
			}
		if (!fnear)
			{
			NoiseFishX := FishBarLeft + NoiseFishPrev
			return true
			}
		}
	if (NoiseFishT > 0 and ((tnow - NoiseFishT) / QpcFreq) < 0.6)
		{
		fbestd := 999999
		k := 1
		while (k <= nf)
			{
			fd := Abs(fX[k] - NoiseFishPrev)
			if (fd < fbestd)
				{
				fbestd := fd
				fpick := fX[k]
				}
			k++
			}
		}
	NoiseFishX := FishBarLeft + fpick
	NoiseFishFresh := true
	NoiseFishPrev := fpick
	NoiseFishT := tnow
	return true
}

;====================================================================================================;

BellonaScan() {
	global pCaptureBits, CaptureW, CaptureH
	global BelA, BelB, BelF, BelOK, BelSeen
	BelSeen := false
	BelA := [0, 0]
	BelB := [0, 0]
	BelF := [-1, -1]
	BelOK := [false, false]
	step := 4
	ncol := CaptureW // step
	col := []
	i := 0
	while (i < ncol)
		{
		x := i * step
		s := 0
		c := 0
		y := 5
		while (y < CaptureH - 5)
			{
			v := NumGet(pCaptureBits + 0, (y*CaptureW + x)*4, "UInt")
			s += ((v & 0xFF) + ((v >> 8) & 0xFF) + ((v >> 16) & 0xFF)) // 3
			c++
			y += 4
			}
		col[i] := (c > 0) ? (s // c) : 0
		i++
		}
	pref := []
	pref[0] := 0
	i := 0
	while (i < ncol)
		{
		pref[i+1] := pref[i] + col[i]
		i++
		}
	halfc := ncol // 2
	gapmax := Round(ncol * 0.035)
	if (gapmax < 4)
		gapmax := 4
		minw := Round(halfc * 0.15)
		maxw := Round(halfc * 0.85)
	sd := 1
	while (sd <= 2)
		{
		lo := (sd = 1) ? 0 : halfc
		hi := (sd = 1) ? halfc : ncol
		hist := []
		bi := 0
		while (bi < 64)
			{
			hist[bi] := 0
			bi++
			}
		k := 0
		i := lo
		while (i < hi)
			{
			bi := col[i] // 4
			if (bi > 63)
				bi := 63
			if (bi < 0)
				bi := 0
			hist[bi] := hist[bi] + 1
			k++
			i++
			}
		need := Round(k * 0.20)
		acc := 0
		bg := 0
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				bg := bi * 4
				break
				}
			bi++
			}
		need := Round(k * 0.98)
		acc := 0
		pk := 255
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				pk := bi * 4
				break
				}
			bi++
			}
		thr := bg + ((pk - bg) * 0.40)
		if (thr < bg + 25)
			thr := bg + 25

		bestLen := 0
		bestS := -1
		bestE := -1
		rs := -1
		re := -1
		gap := 0
		i := lo
		while (i < hi)
			{
			if (col[i] >= thr)
				{
				if (rs < 0)
					rs := i
				re := i
				gap := 0
				}
			else if (rs >= 0)
				{
				gap++
				if (gap > gapmax)
					{
					if (re - rs > bestLen)
						bestLen := re - rs, bestS := rs, bestE := re
					rs := -1
					gap := 0
					}
				}
			i++
			}
		if (rs >= 0 and re - rs > bestLen)
			bestLen := re - rs, bestS := rs, bestE := re

		barw := bestLen + 1
		bestIn := (bestS >= 0) ? ((pref[bestE+1] - pref[bestS]) / barw) : 0
		bestSc := bestIn - bg
		if (bestS >= 0 and barw >= minw and barw <= maxw and bestSc >= 28)
			BelSeen := true
		if (bestS >= 0 and barw >= minw and barw <= maxw and bestSc >= 120)
			{
			BelA[sd] := bestS * step
			BelB[sd] := bestE * step
			BelOK[sd] := true
			fhi := bestIn * 0.62
			flo := (pk - bg) * 0.15
			if (flo < 20)
				flo := 20
			flo := bg + flo
			wcap := Round(halfc * 0.10)
			if (wcap < 2)
				wcap := 2
			s0 := bestS - 3
			if (s0 < lo)
				s0 := lo
			s1 := bestE + 3
			if (s1 > hi - 1)
				s1 := hi - 1
			fbest := 99999
			fs := -1
			fe := -1
			cs := -1
			i := s0
			while (i <= s1 + 1)
				{
				isf := (i <= s1 and col[i] >= flo and col[i] < fhi)
				if (isf)
					{
					if (cs < 0)
						cs := i
					}
				else if (cs >= 0)
					{
					ce := i - 1
					if (ce - cs <= wcap and cs > lo and ce < hi - 1 and col[cs-1] >= fhi and col[ce+1] >= fhi)
						{
						cm := (pref[ce+1] - pref[cs]) / (ce - cs + 1)
						if (cm < fbest)
							fbest := cm, fs := cs, fe := ce
						}
					cs := -1
					}
				i++
				}
			if (fs >= 0)
				BelF[sd] := ((fs + fe) * step) // 2
			}
		sd++
		}
	return (BelOK[1] or BelOK[2]) ? 2 : (BelSeen ? 1 : 0)
}

BellonaDrive(sd) {
	global BelA, BelB, BelF, BelOK, BelPrevF, BelPrevB, BelPrevT, BelVel, BelBVel, BelDown, QpcFreq
	global BelSide, BelAcc, BelBias, WindowWidth
	if (!BelOK[sd])
		return
	bar := (BelA[sd] + BelB[sd]) / 2
	fish := BelF[sd]
	if (fish < 0)
		{
		if (BelSide[sd] = 0)
			return
		BelAcc[sd] := 0
		BellonaSet(sd, BelSide[sd] > 0)
		return
		}
	rs := WindowWidth / 2560
	if (rs <= 0)
		rs := 1
	BelSide[sd] := (fish > bar) ? 1 : -1
	DllCall("QueryPerformanceCounter", "Int64*", tn)
	dt := 0
	if (BelPrevT[sd] > 0)
		{
		dt := (tn - BelPrevT[sd]) / QpcFreq
		if (dt > 0.0005 and dt < 0.5)
			{
			BelVel[sd]  := BelVel[sd]  * 0.4 + ((fish - BelPrevF[sd]) / dt) * 0.6
			BelBVel[sd] := BelBVel[sd] * 0.4 + ((bar  - BelPrevB[sd]) / dt) * 0.6
			}
		}
	BelPrevT[sd] := tn
	BelPrevF[sd] := fish
	BelPrevB[sd] := bar
	e := bar - fish
	rel := BelBVel[sd] - BelVel[sd]
	if (Abs(e) <= 36 * rs and Abs(rel) <= 120 * rs)
		{
		kp := 0.0122 / rs
		kd := 0.00488 / rs
		if (dt > 0 and dt < 0.1)
			{
			BelBias[sd] := BelBias[sd] - (0.25 * kp * e * dt)
			if (BelBias[sd] > 0.2)
				BelBias[sd] := 0.2
			if (BelBias[sd] < -0.2)
				BelBias[sd] := -0.2
			}
		duty := 0.463 + BelBias[sd] - (kp * e) - (kd * rel)
		if (duty < 0)
			duty := 0
		if (duty > 1)
			duty := 1
		BelAcc[sd] := BelAcc[sd] + duty
		if (BelAcc[sd] >= 1)
			{
			BelAcc[sd] := BelAcc[sd] - 1
			want := true
			}
		else
			want := false
		}
	else
		want := ((e + (rel * 0.5)) < 0)
	BellonaSet(sd, want)
}

BellonaSet(sd, want) {
	global BelDown
	btn := (sd = 1) ? "LButton" : "RButton"
	if (want and (!BelDown[sd] or !GetKeyState(btn)))
		{
		if (sd = 1)
			send {lbutton down}
		else
			send {rbutton down}
		BelDown[sd] := true
		}
	else if (!want and (BelDown[sd] or GetKeyState(btn)))
		{
		if (sd = 1)
			send {lbutton up}
		else
			send {rbutton up}
		BelDown[sd] := false
		}
}

BellonaRelease() {
	global BelDown
	send {lbutton up}
	send {rbutton up}
	BelDown := [false, false]
}

LineScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global LineList, LineFishX, LineNoteX, LineFound, LineScanned
	global LineBarL, LineBarW, LineBarAge, LineFishSeen, SpecialRod, DarkHoldN, DarkFlashing, DarkAcc
	if (LineScanned)
		return LineFound
	LineScanned := true
	if (SpecialRod = "Darkheart")
		{
		if (FrameIsDark())
			{
			DarkHoldN := DarkHoldN + 1
			if (DarkHoldN <= 45 and LineBarW >= 1)
				{
				if (!DarkFlashing)
					DarkAcc := 0
				DarkFlashing := true
				return LineFound
				}
			}
		else
			{
			DarkHoldN := 0
			DarkFlashing := false
			}
		}
	LineFound := false
	LineFishSeen := false
	LineFishX := -1
	LineNoteX := -1
	LineList := []

	VarSetCapacity(HitBuf, CaptureW * 4, 0)
	pHits := &HitBuf

	pFn := LineHitsFn()
	if (pFn)
		rows := DllCall(pFn, "Ptr", pCaptureBits, "Int", CaptureW, "Int", CaptureH, "Ptr", pHits, "Int")
	else
		rows := LineHitsAhk(pCaptureBits, CaptureW, CaptureH, pHits)

	need := Round(rows * 0.5)
	if (need < 2)
		need := 2

	s := -1
	p := -1
	x := 1
	q := pHits + 4
	while (x < CaptureW)
		{
		if (NumGet(q + 0, 0, "UInt") >= need)
			{
			if (s < 0)
				s := x, p := x
			else if (x - p <= 3)
				p := x
			else
				{
				LineList.Push((s + p) // 2)
				s := x
				p := x
				}
			}
		x++, q += 4
		}
	if (s >= 0)
		{
		LineList.Push((s + p) // 2)
		}

	bestGap := 999
	fi := -1
	i := 1
	while (i < LineList.Length())
		{
		gap := LineList[i+1] - LineList[i]
		if (gap >= 4 and gap <= 20 and gap < bestGap)
			bestGap := gap, fi := i
		i++
		}
	pinCol := false
	if (SpecialRod = "Pinions Aria" and PinMarkerX(fcx))
		{
		pinCol := true
		ci := 1
		while (ci < LineList.Length())
			{
			cg := LineList[ci+1] - LineList[ci]
			if (cg >= 3 and cg <= 20 and Abs(((LineList[ci] + LineList[ci+1]) / 2) - fcx) <= 8)
				{
				fcx := (LineList[ci] + LineList[ci+1]) / 2
				break
				}
			ci++
			}
		}
	else if (fi < 0)
		{
		LineBarAge := LineBarAge + 1
		return false
		}
	else
		fcx := (LineList[fi] + LineList[fi+1]) / 2
	LineFishX := FishBarLeft + fcx
	LineFishSeen := true

	others := []
	i := 1
	while (i <= LineList.Length())
		{
		if (pinCol ? (Abs(LineList[i] - fcx) > 8 and LineList[i] >= 3 and LineList[i] <= CaptureW - 4) : (i != fi and i != fi + 1))
			others.Push(LineList[i])
		i++
		}

	if (others.Length() >= 2)
		{
		expW := (LineBarW >= 40) ? LineBarW : 0
		lo := -1
		hi := -1
		if (pinCol)
			{
			oLft := others[1]
			oRgt := others[others.Length()]
			if (oRgt - oLft >= 40 and oRgt - oLft <= CaptureW * 0.75)
				{
				lo := oLft
				hi := oRgt
				if (expW > 0 and Abs((oRgt - oLft + 1) - expW) > expW * 0.25)
					{
					pi := 1
					while (pi < others.Length())
						{
						pj := pi + 1
						while (pj <= others.Length())
							{
							if (Abs((others[pj] - others[pi] + 1) - expW) <= 6)
								{
								lo := others[pi]
								hi := others[pj]
								pi := others.Length()
								break
								}
							pj++
							}
						pi++
						}
					}
				}
			}
		vgSkip := false
		if (SpecialRod = "Verdant Oath")
			{
			vgSkip := true
			vgo1 := Round(CaptureW * 0.005)
			vgo2 := Round(CaptureW * 0.018)
			vgR := []
			vgL := []
			vgi := 1
			while (vgi <= LineList.Length())
				{
				vgR[vgi] := LineGreenAt(LineList[vgi] + vgo1, LineList[vgi] + vgo2)
				vgL[vgi] := LineGreenAt(LineList[vgi] - vgo1, LineList[vgi] - vgo2)
				vgi++
				}
			vgi := 1
			while (vgi < LineList.Length())
				{
				if (vgR[vgi] and vgi != fi and vgi != fi + 1)
					{
					vgj := vgi + 1
					while (vgj <= LineList.Length())
						{
						if (vgL[vgj] and vgj != fi and vgj != fi + 1 and LineList[vgj] - LineList[vgi] >= 40 and (lo < 0 or LineList[vgj] - LineList[vgi] > hi - lo))
							{
							lo := LineList[vgi]
							hi := LineList[vgj]
							}
						vgj++
						}
					}
				vgi++
				}
			if (lo < 0 and expW > 0)
				{
				vgi := 1
				while (vgi <= LineList.Length())
					{
					vge := LineList[vgi]
					if (vgi != fi and vgi != fi + 1 and vgR[vgi] and LineBrownAt(vge - vgo1))
						{
						lo := vge
						hi := vge + expW - 1
						if (hi > CaptureW - 1)
							hi := CaptureW - 1
						break
						}
					if (vgi != fi and vgi != fi + 1 and vgL[vgi] and LineBrownAt(vge + vgo1))
						{
						hi := vge
						lo := vge - expW + 1
						if (lo < 0)
							lo := 0
						break
						}
					vgi++
					}
				}
			}
		bestScore := 999999
		oi := vgSkip ? others.Length() : 1
		while (lo < 0 and oi < others.Length())
			{
			oj := oi + 1
			while (oj <= others.Length())
				{
				sep := others[oj] - others[oi]
				if (sep >= 40)
					{
					score := (expW > 0) ? Abs(sep - expW) : Abs(sep - 200)
					if (score < bestScore)
						{
						bestScore := score
						lo := others[oi]
						hi := others[oj]
						}
					}
				oj++
				}
			oi++
			}
		if (lo >= 0)
			{
			LineBarL := FishBarLeft + lo
			LineBarW := hi - lo + 1
			LineBarAge := 0
			}
		else
			LineBarAge := LineBarAge + 1
		}
	else if (others.Length() = 1)
		{
		e := others[1]
		lsSide := ""
		ext := (LineBarW >= 40) ? LineBarW : 200
		if (LineBarW >= 40)
			{
			lsHL := e - LineBarW + 1
			lsHR := e + LineBarW - 1
			lsOkL := (lsHL >= -12)
			lsOkR := (lsHR <= CaptureW + 11)
			if (lsOkL and lsOkR)
				{
				if (LineBarAge <= 3)
					{
					lsPrevL := LineBarL - FishBarLeft
					lsSide := (Abs(lsHL - lsPrevL) <= Abs(e - lsPrevL)) ? "L" : "R"
					}
				else if (Abs(lsHL - fcx) <= 14 or lsHL <= 2)
					lsSide := "L"
				else if (Abs(lsHR - fcx) <= 14 or lsHR >= CaptureW - 3)
					lsSide := "R"
				}
			else if (lsOkL)
				lsSide := "L"
			else if (lsOkR)
				lsSide := "R"
			}
		if (lsSide = "")
			{
			spL := ColSpread(e - 120, e - 6, fcx)
			spR := ColSpread(e + 6, e + 120, fcx)
			if (spL > spR and spL > 0)
				lsSide := "L"
			else if (spR > 0)
				lsSide := "R"
			}
		if (lsSide = "L")
			{
			bl := e - ext + 1
			if (bl < 0)
				bl := 0
			LineBarL := FishBarLeft + bl
			LineBarW := e - bl + 1
			LineBarAge := 0
			}
		else if (lsSide = "R")
			{
			br := e + ext - 1
			if (br > CaptureW - 1)
				br := CaptureW - 1
			LineBarL := FishBarLeft + e
			LineBarW := br - e + 1
			LineBarAge := 0
			}
		else
			LineBarAge := LineBarAge + 1
		}
	else
		LineBarAge := LineBarAge + 1

	if (LineBarW < 1 or LineBarAge > 12)
		return false

	LineFound := true
	return true
}

LineColAvg(x, ByRef cr, ByRef cg, ByRef cb) {
	global pCaptureBits, CaptureW, CaptureH
	cr := 0
	cg := 0
	cb := 0
	if (x < 0 or x >= CaptureW)
		return false
	n := 0
	y := 0
	while (y < CaptureH)
		{
		px := NumGet(pCaptureBits + (y * CaptureW + x) * 4, 0, "UInt")
		cb += px & 0xFF
		cg += (px >> 8) & 0xFF
		cr += (px >> 16) & 0xFF
		n++
		y += 12
		}
	if (!n)
		return false
	cr /= n
	cg /= n
	cb /= n
	return true
}

LineGreenAt(x1, x2) {
	if (LineColAvg(x1, cr, cg, cb) and cg - ((cr > cb) ? cr : cb) > 30)
		return true
	if (LineColAvg(x2, cr, cg, cb) and cg - ((cr > cb) ? cr : cb) > 30)
		return true
	return false
}

LineBrownAt(x) {
	return (LineColAvg(x, cr, cg, cb) and cr > cg + 10 and cr > cb + 20)
}

VerdantBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, VgBarL, VgBarW, VgPrm, VgPrmReady
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return false
	if (!VgPrmReady)
		{
		PcSetPrm(VgPrm, "0x3B8113", 0, 1, 0)
		VgPrmReady := true
		}
	vgLs := []
	vgRs := []
	for vgI, vgY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		vgP := pCaptureBits + vgY * CaptureW * 4
		vgA := PcFind(vgP, CaptureW, 4, VgPrm)
		if (vgA < 0)
			continue
		vgB := PcFind(vgP + (CaptureW - 1) * 4, CaptureW, -4, VgPrm)
		if (vgB < 0)
			continue
		vgB := CaptureW - 1 - vgB
		if (vgB - vgA + 1 >= CaptureW * 0.04 and vgB - vgA + 1 <= CaptureW * 0.85)
			{
			vgLs.Push(vgA)
			vgRs.Push(vgB)
			}
		}
	if (vgLs.Length() < 2)
		return false
	vgA := (vgLs.Length() = 3) ? MedianOf(vgLs) : ((vgLs[1] > vgLs[2]) ? vgLs[1] : vgLs[2])
	vgB := (vgRs.Length() = 3) ? MedianOf(vgRs) : ((vgRs[1] < vgRs[2]) ? vgRs[1] : vgRs[2])
	if (vgB - vgA + 1 < CaptureW * 0.04)
		return false
	vgO := Round(CaptureW * 0.005) + 1
	if (!LineBrownAt(vgA - vgO) and !LineBrownAt(vgB + vgO))
		return false
	VgBarL := FishBarLeft + vgA
	VgBarW := vgB - vgA + 1
	return true
}

VerdantFishX() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, FishColor, FishBarColorTolerance, LastFishX
	global VgPrmF, VgPrmFI
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return -1
	vfL := ColorListParse(FishColor)
	if (vfL.n < 1)
		return -1
	vfMaxW := Round(CaptureW * 0.04)
	for vfI, vfY in [Floor(CaptureH * 0.50), Floor(CaptureH * 0.30), Floor(CaptureH * 0.70)]
		{
		vfP := pCaptureBits + vfY * CaptureW * 4
		vfBest := -1
		vfBestD := 999999
		Loop, % vfL.n
			{
			vfK := A_Index
			vfHex := Format("0x{:02X}{:02X}{:02X}", vfL.r[vfK], vfL.g[vfK], vfL.b[vfK])
			PcSetPrm(VgPrmF, vfHex, FishBarColorTolerance, 0, 0)
			PcSetPrm(VgPrmFI, vfHex, FishBarColorTolerance, 0, 1)
			vfN := 0
			vfX := 0
			while (vfX < CaptureW and vfN < 24)
				{
				vfS := PcFind(vfP + vfX * 4, CaptureW - vfX, 4, VgPrmF)
				if (vfS < 0)
					break
				vfS += vfX
				vfE := PcFind(vfP + (vfS + 1) * 4, CaptureW - vfS - 1, 4, VgPrmFI)
				vfE := (vfE < 0) ? CaptureW - 1 : vfS + vfE
				vfN++
				if (vfE - vfS + 1 >= 3 and vfE - vfS + 1 <= vfMaxW)
					{
					vfC := (vfS + vfE) / 2
					vfD := (LastFishX >= 0) ? Abs(FishBarLeft + vfC - LastFishX) : 0
					if (vfD < vfBestD)
						{
						vfBestD := vfD
						vfBest := vfC
						}
					}
				vfX := vfE + 1
				}
			}
		if (vfBest >= 0)
			{
			LastFishX := FishBarLeft + vfBest
			return LastFishX
			}
		}
	return -1
}

PinMarkerX(ByRef cx) {
	global pCaptureBits, CaptureW, CaptureH, CapExtra, WindowHeight
	global PnPrmM, PnPrmMI, PnPrmC, PnPrmCI, PnPrmReady
	cx := -1
	if (!pCaptureBits or CaptureW < 40)
		return false
	if (!PnPrmReady)
		{
		PcSetPrm(PnPrmM, "0xC580FC", 36, 0, 0)
		PcSetPrm(PnPrmMI, "0xC580FC", 36, 0, 1)
		PcSetPrm(PnPrmC, "0x5AF7F9", 45, 0, 0)
		PcSetPrm(PnPrmCI, "0x5AF7F9", 45, 0, 1)
		PnPrmReady := true
		}
	PinRowsM := [Round(WindowHeight * 0.030), Round(WindowHeight * 0.034), Round(WindowHeight * 0.026), Round(WindowHeight * 0.038), Round(WindowHeight * 0.042)]
	PinRowsC := [0 - Round(WindowHeight * 0.009), 0 - Round(WindowHeight * 0.006), 0 - Round(WindowHeight * 0.012)]
	for i, rr in [PinRowsM[1], PinRowsM[2], PinRowsM[3], PinRowsM[4], PinRowsM[5], PinRowsC[1], PinRowsC[2], PinRowsC[3]]
		{
		if (rr >= CaptureH + 20 + CapExtra or rr < -17)
			continue
		p := pCaptureBits + (rr * CaptureW * 4)
		if (i <= 5)
			{
			i0 := PcFind(p, CaptureW, 4, PnPrmM)
			if (i0 < 0)
				continue
			i1 := PcFind(p + (i0 + 1) * 4, CaptureW - i0 - 1, 4, PnPrmMI)
			}
		else
			{
			i0 := PcFind(p, CaptureW, 4, PnPrmC)
			if (i0 < 0)
				continue
			i1 := PcFind(p + (i0 + 1) * 4, CaptureW - i0 - 1, 4, PnPrmCI)
			}
		w := (i1 < 0) ? (CaptureW - i0) : (i1 + 1)
		if (w < 2 or w > 30)
			continue
		cx := i0 + (w / 2)
		return true
		}
	return false
}

LineHitsAhk(pBits, w, h, pHits) {
	rowBytes := w * 4
	rows := 0
	y := 0
	while (y < h)
		{
		p := pBits + (y * rowBytes)
		pe := p + rowBytes
		px := NumGet(p + 0, 0, "UInt")
		prev := (px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)
		p += 4, q := pHits + 4
		while (p < pe)
			px := NumGet(p + 0, 0, "UInt"), cur := (px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF), (cur - prev > 54 or prev - cur > 54) ? NumPut(NumGet(q + 0, 0, "UInt") + 1, q + 0, 0, "UInt") : 0, prev := cur, p += 4, q += 4
		rows++
		y += 3
		}
	return rows
}

LineHitsFn() {
	static pFn := "", Hex := "53565755415431C04531D24189D349C1E3024539C20F8D5B000000498BF2490FAFF34801CE0FB61E0FB67E0101FB0FB67E0201FBBF0100000039D77D310FB62CBE440FB664BE014401E5440FB664BE024401E54189EC4129DC790341F7DC4183FC367E0441FF04B989EBFFC7EBCBFFC04183C203EB9C415C5D5F5E5BC3"
	if (pFn != "")
		return pFn
	pFn := 0
	if (A_PtrSize != 8)
		return 0
	n := StrLen(Hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(Hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	tw := 157, th := 23
	VarSetCapacity(tBits, tw * th * 4, 0)
	seed := 12345
	Loop, % tw * th
		{
		seed := Mod(seed * 1103515245 + 12345, 2147483648)
		v := (seed >> 8) & 0xFFFFFFFF
		if (Mod(A_Index, 7) < 3)
			v := v & 0x3F3F3F3F
		NumPut(v, tBits, (A_Index - 1) * 4, "UInt")
		}
	VarSetCapacity(hA, tw * 4, 0)
	VarSetCapacity(hB, tw * 4, 0)
	rA := LineHitsAhk(&tBits, tw, th, &hA)
	rB := DllCall(p, "Ptr", &tBits, "Int", tw, "Int", th, "Ptr", &hB, "Int")
	same := (rA = rB)
	anyHit := false
	Loop, %tw%
		{
		a := NumGet(hA, (A_Index - 1) * 4, "UInt")
		if (a != NumGet(hB, (A_Index - 1) * 4, "UInt"))
			same := false
		if (a)
			anyHit := true
		}
	if (!same or !anyHit)
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	pFn := p
	return pFn
}

PinionScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, BarScanRow
	global FishColor, FishBarColorTolerance, NoteColor, NoteColorTolerance
	global PinFishX, PinNoteX, PinFound
	PinFishX := -1
	PinNoteX := -1
	PinFound := false
	row := BarScanRow
	if (row < 0 or row >= CaptureH)
		row := CaptureH // 2
	rowOff := row * CaptureW * 4

	fb := ToBGR(ColMain(FishColor))
	fB := (fb >> 16) & 0xFF
	fG := (fb >> 8) & 0xFF
	fR := fb & 0xFF
	ftol := FishBarColorTolerance
	if (ftol < 4)
		ftol := 4

	nb := ToBGR(NoteColor)
	nB := (nb >> 16) & 0xFF
	nG := (nb >> 8) & 0xFF
	nR := nb & 0xFF
	ntol := NoteColorTolerance
	if (ntol < 4)
		ntol := 4

	bestW := 0
	fRunS := -1
	fRunE := -1
	nRunS := -1
	nRunE := -1
	x := 0
	while (x <= CaptureW)
		{
		isF := false
		isN := false
		if (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			isF := (Abs(b - fB) <= ftol and Abs(g - fG) <= ftol and Abs(r - fR) <= ftol)
			isN := (Abs(b - nB) <= ntol and Abs(g - nG) <= ntol and Abs(r - nR) <= ntol)
			}
		if (isF)
			{
			if (fRunS < 0)
				fRunS := x
			fRunE := x
			}
		else if (fRunS >= 0)
			{
			w := fRunE - fRunS + 1
			if (w >= 3 and w <= 25 and w > bestW)
				{
				bestW := w
				PinFishX := FishBarLeft + ((fRunS + fRunE) / 2)
				}
			fRunS := -1
			}
		if (isN)
			{
			if (nRunS < 0)
				nRunS := x
			nRunE := x
			}
		else if (nRunS >= 0)
			{
			w := nRunE - nRunS + 1
			if (w >= 2 and w <= 10 and PinNoteX < 0)
				PinNoteX := FishBarLeft + ((nRunS + nRunE) / 2)
			nRunS := -1
			}
		x++
		}
	PinFound := (PinFishX >= 0)
	return PinFound
}


; --- Noiseform zone gimmick -------------------------------------------------------------------

TotemMaybeRun:
if (!TotemAuto or !MacroRunning)
	return
if (!TotemPreDone)
	{
	if (TotemLastCheck and (A_TickCount - TotemLastCheck) < (TotemPollSec * 1000))
		return
	; not read during the last bobber wait (it was too short) - one read here
	tooltip, Current Task: Checking Totems, %TooltipX%, %Tooltip7%, 7
	gosub, TotemAssess
	}
TotemPreDone := false
; nothing to pop: no time is spent here at all
if (TotemPending = "")
	return
TotemPending := ""
tooltip, Current Task: Checking Totems, %TooltipX%, %Tooltip7%, 7
tooltip, , , , 8
if (WhLastCatchTick)
	{
	TotemSinceCatch := A_TickCount - WhLastCatchTick
	if (TotemSinceCatch >= 0 and TotemSinceCatch < TA("totemcatch", 0))
		Sleep, % Tm(TA("totemcatch", 0) - TotemSinceCatch)
	}
; a totem is due: the careful check (two matching reads) runs before anything is popped
TotemSkipNo := true
gosub, TotemRunCycle
TotemSkipNo := false
return

; one read of the totem icons and the decision, nothing popped: TotemPending = the totem that is due ("" = none)
TotemAssess:
TotemPending := ""
TotemAssessOnly := true
TotemAssessOk := false
TotemAsT0 := A_TickCount
gosub, TotemRunCycle
TotemAssessOnly := false
TotemLastCheck := A_TickCount
; a failed read is left to the restart (it tries again the normal way)
TotemPreDone := TotemAssessOk
return

;====================================================================================================;

TotemRunCycle:
TotemDidPop := false
TotemPass := 0
TotemCyclePopped := ","
if (!TotemSkipNo)
	TotemCheckNo++
TotemLoop:
TotemPass++
if (TotemPass > 6 or !MacroRunning)
	goto TotemDone
if (!TotemStripInit())
	goto TotemDone
TotemPrevSig := ""
TotemSettleN := 0
TotemSettled := false
Loop, 8
	{
	if (!MacroRunning)
		goto TotemDone
	TotemSig := ""
	TotemRdT := A_TickCount
	if (TotemCaptureStrip() and TotemReadState())
		TotemSig := TotemTime . "|" . TotemWeather . "|" . TotemEvents
	TotemRdT := A_TickCount - TotemRdT
	TotemReadMs := (TotemReadMs = "") ? TotemRdT : Round(0.7 * TotemReadMs + 0.3 * TotemRdT)
	if (TotemAssessOnly)
		{
		; one read decides - a pop is still checked carefully at the restart before it happens
		if (TotemSig = "")
			goto TotemDone
		TotemAssessOk := true
		TotemSettled := true
		break
		}
	if (TotemSig != "" and TotemSig = TotemPrevSig)
		{
		TotemSettled := true
		break
		}
	TotemPrevSig := TotemSig
	TotemSettleN := TotemSettleN + 1
	Sleep, % Tm(TA("totemsettle", 250))
	}
if (!TotemSettled)
	goto TotemDone
TotemSlotN := TotemSlotCount()
TotemTaken := {}
for TotemAsI, TotemAsNm in [TotemSel1, TotemSel2, TotemSel3]
	{
	if (!TotemIsEventName(TotemAsNm))
		continue
	TotemAsK := TotemSlotOfName(TotemAsNm)
	if (TotemAsK)
		{
		TotemAssumeSet(TotemAsNm, TotemAsK)
		TotemAssumeSrc[TotemAsNm] := "name"
		TotemTaken[TotemAsK] := TotemAsNm
		}
	}
TotemBindNear()
if (TotemLastPop != "")
	{
	if (TotemLastPop = "Sundial")
		TotemSeen := (TotemTime = TotemWantTime)
	else
		TotemSeen := TotemHas(TotemLastPop)
	if (!TotemSeen and TotemIsEventName(TotemLastPop))
		{
		TotemAsK := TotemNewUnknownSlot(TotemLastPopSigs)
		if (TotemAsK)
			{
			TotemAssumeSet(TotemLastPop, TotemAsK)
			TotemAssumeSrc[TotemLastPop] := "pop"
			TotemAssumeAt[TotemLastPop] := A_TickCount
			TotemTaken[TotemAsK] := TotemLastPop
			TotemBound[TotemLastPop] := 1
			TotemCool.Delete(TotemLastPop)
			TotemSeen := true
			}
		}
	if (!TotemSeen and !TotemOnCooldown(TotemLastPop))
		TotemCool[TotemLastPop] := A_TickCount + ((TotemLastPop = "Sundial") ? 90000 : 180000)
	if (TotemSeen or !TotemIsEventName(TotemLastPop) or A_TickCount > TotemLastPopUntil)
		TotemLastPop := ""
	}
TotemBindRest()
for TotemAsNm, TotemAsV in TotemCool.Clone()
	{
	if (TotemAsNm != "Sundial" and TotemHas(TotemAsNm))
		TotemCool.Delete(TotemAsNm)
	}
if (TotemLastPop != "")
	goto TotemDone
TotemNext := ""
TotemNextKey := ""
TotemFor := ""
for i, sel in [TotemSel1, TotemSel2, TotemSel3]
	{
	if (sel = "" or sel = "None")
		continue
	if (sel = "Day" or sel = "Night")
		tkey := TotemKeySundial
	else
		{
		tkv := "TotemKey" . sel
		tkey := %tkv%
		}
	if (tkey = "")
		continue
	if (TotemHas(sel))
		continue
	if (TotemGroupBusy(sel))
		continue
	if (TotemOnCooldown(sel))
		continue
	if (TotemWeatherConflict(sel))
		continue
	if (TotemIsWeatherState(sel) and TotemWeather = "Unknown")
		continue
	tneed := TotemNeedsTime(sel)
	if (tneed != "" and TotemTime = "")
		continue
	if (tneed != "" and TotemTime != "" and TotemTime != tneed)
		{
		if (TotemConflict(sel))
			continue
		if (TotemKeySundial = "" or TotemOnCooldown("Sundial"))
			continue
		TotemNext := "Sundial"
		TotemFor := sel
		TotemNextKey := TotemKeySundial
		TotemWantTime := tneed
		break
		}
	if (sel = "Day" or sel = "Night")
		continue
	TotemNext := sel
	TotemFor := sel
	TotemNextKey := tkey
	break
	}
if (TotemNext = "")
	goto TotemDone
if (InStr(TotemCyclePopped, "," . TotemNext . ","))
	goto TotemDone
if (TotemAssessOnly)
	{
	TotemPending := TotemNext
	goto TotemDone
	}
tooltip, Current Task: Totem - %TotemNext%, %TooltipX%, %Tooltip7%, 7
send {%TotemNextKey%}
Sleep, % Tm(TA("totemkey", 300))
click
TotemDidPop := true
TotemCyclePopped .= TotemNext . ","
TotemLastPop := TotemNext
TotemLastPopSigs := TotemEvtSigs
TotemLastPopUntil := A_TickCount + 60000
if (TotemNext = "Sundial")
	WhEvent("totem", "Sundial Totem - changing the time to " . TotemWantTime
		. ((TotemFor = "Day" or TotemFor = "Night") ? "" : " for the " . TotemFor . " Totem"))
else
	WhEvent("totem", TotemNext . " Totem")
if (TotemNext = "Sundial")
	{
	TotemWaited := 0
	while (MacroRunning and TotemWaited < TA("totemmax", 40000))
		{
		Sleep, % Tm(1000)
		TotemWaited := TotemWaited + 1000
		TotemWaitS := TotemWaited // 1000
		tooltip, Current Task: Totem - waiting for %TotemWantTime% (%TotemWaitS%s), %TooltipX%, %Tooltip7%, 7
		if (!TotemCaptureStrip())
			continue
		TotemReadState()
		if (TotemTime = TotemWantTime)
			break
		}
	}
else
	Sleep, % Tm(TotemActDelay)
if (!MacroRunning)
	goto TotemDone
goto TotemLoop

TotemDone:
if (TotemDidPop and RodSlotKey != "")
	{
	send {%RodSlotKey%}
	Sleep, % Tm(TA("totemdone", 400))
	}
return

;====================================================================================================;

TotemHasByName(nm) {
	global TotemWeather, TotemEvents, TotemTime
	if (nm = "Day" or nm = "Night")
		return (TotemTime = nm)
	if (nm = "Clearcast")
		return (TotemWeather = "Clear")
	if (nm = "Tempest")
		return (TotemWeather = "Rain")
	if (nm = "Windset")
		return (TotemWeather = "Windy")
	if (nm = "Smokescreen")
		return (TotemWeather = "Foggy")
	if (nm = "Shiny" or nm = "Sparkling")
		return (InStr(TotemEvents, "Shiny,") or InStr(TotemEvents, "Sparkling,")) ? true : false
	return InStr(TotemEvents, nm . ",") ? true : false
}

TotemHas(nm) {
	global TotemAssume
	if (TotemHasByName(nm))
		return true
	for aNm, aSig in TotemAssume
		{
		if (aNm = nm or ((nm = "Shiny" or nm = "Sparkling") and (aNm = "Shiny" or aNm = "Sparkling")))
			return true
		}
	return false
}

TotemIsEventName(nm) {
	return (nm = "Aurora" or nm = "Starfall" or nm = "Eclipse" or nm = "Shiny" or nm = "Sparkling" or nm = "Mutation")
}

TotemGroupOf(nm) {
	if (nm = "Shiny" or nm = "Sparkling" or nm = "Mutation")
		return "Shiny,Sparkling,Mutation"
	return ""
}

TotemGroupBusy(nm) {
	grp := TotemGroupOf(nm)
	if (grp = "")
		return false
	for i, other in StrSplit(grp, ",")
		{
		if (other = nm or ((nm = "Shiny" or nm = "Sparkling") and (other = "Shiny" or other = "Sparkling")))
			continue
		if (TotemHas(other))
			return true
		}
	return false
}

TotemOnCooldown(nm) {
	global TotemCool
	return (TotemCool.HasKey(nm) and A_TickCount < TotemCool[nm]) ? true : false
}

TotemSigDist(a, b) {
	pa := StrSplit(a, "/")
	pb := StrSplit(b, "/")
	if (pa.MaxIndex() < 4 or pb.MaxIndex() < 4)
		return 999999
	ga := pa[4]
	gb := pb[4]
	d := 0
	i := 0
	while (i < 144)
		{
		dv := SubStr(ga, i * 3 + 1, 3) - SubStr(gb, i * 3 + 1, 3)
		d := d + ((dv < 0) ? 0 - dv : dv)
		i++
		}
	d := d + Abs(pa[3] - pb[3]) * 8
	sa := pa[2] + 0
	sb := pb[2] + 0
	if (pa[1] >= 0 and pb[1] >= 0 and sa >= 20 and sb >= 20)
		{
		hd := Abs(pa[1] - pb[1])
		if (hd > 180)
			hd := 360 - hd
		d := d + hd * 20 + Abs(sa - sb) * 15
		}
	else if (sa < 20 and sb < 20)
		d := d + Abs(sa - sb) * 15
	else
		d := d + 2000
	return d
}

TotemSlotCount() {
	global TotemEvents
	if (TotemEvents = "")
		return 0
	return StrSplit(RTrim(TotemEvents, ","), ",").MaxIndex()
}

TotemSlotName(k) {
	global TotemEvents
	if (TotemEvents = "" or k < 1)
		return ""
	ns := StrSplit(RTrim(TotemEvents, ","), ",")
	return (k <= ns.MaxIndex()) ? ns[k] : ""
}

TotemSlotSig(k) {
	global TotemEvtSigs
	if (TotemEvtSigs = "" or k < 1)
		return ""
	ss := StrSplit(RTrim(TotemEvtSigs, ","), ",")
	return (k <= ss.MaxIndex()) ? ss[k] : ""
}

TotemSlotOfName(nm) {
	global TotemEvents
	if (TotemEvents = "")
		return 0
	for i, n in StrSplit(RTrim(TotemEvents, ","), ",")
		{
		if (n = nm or ((nm = "Shiny" or nm = "Sparkling") and (n = "Shiny" or n = "Sparkling")))
			return i
		}
	return 0
}

TotemSortByD(arr) {
	i := 2
	while (i <= arr.MaxIndex())
		{
		v := arr[i]
		j := i - 1
		while (j >= 1 and arr[j].d > v.d)
			{
			arr[j + 1] := arr[j]
			j--
			}
		arr[j + 1] := v
		i++
		}
	return arr
}

TotemBindNear() {
	global TotemAssume, TotemAssumeMiss, TotemTaken, TotemSlotN, TotemBound
	TotemBound := {}
	cand := []
	for nm, sig in TotemAssume
		{
		if (TotemHasByName(nm))
			continue
		k := 1
		while (k <= TotemSlotN)
			{
			if (!TotemTaken.HasKey(k) and TotemSlotName(k) = "?")
				{
				d := TotemSigDist(TotemSlotSig(k), sig)
				if (d <= 1900)
					cand.Push({d: d, nm: nm, k: k})
				}
			k++
			}
		}
	TotemSortByD(cand)
	for i, c in cand
		{
		if (TotemBound.HasKey(c.nm) or TotemTaken.HasKey(c.k))
			continue
		TotemAssumeSet(c.nm, c.k)
		TotemTaken[c.k] := c.nm
		TotemBound[c.nm] := 1
		}
	for nm, sig in TotemAssume
		{
		if (TotemHasByName(nm))
			{
			TotemAssumeMiss[nm] := 0
			TotemBound[nm] := 1
			}
		}
}

TotemBindRest() {
	global TotemAssume, TotemAssumeMiss, TotemAssumeSlot, TotemAssumeCnt, TotemAssumeSrc, TotemAssumeAt
	global TotemTaken, TotemSlotN, TotemCheckNo, TotemCool, TotemBound
	for nm, sig in TotemAssume.Clone()
		{
		if (TotemBound.HasKey(nm))
			continue
		k := TotemAssumeSlot[nm]
		if (k and !TotemTaken.HasKey(k) and TotemSlotN = TotemAssumeCnt[nm] and TotemSlotName(k) = "?" and TotemSigDist(TotemSlotSig(k), sig) <= 2800)
			{
			TotemAssumeSet(nm, k)
			TotemTaken[k] := nm
			continue
			}
		if (!TotemAssumeMiss[nm])
			TotemAssumeMiss[nm] := TotemCheckNo
		else if (TotemCheckNo > TotemAssumeMiss[nm])
			{
			if (TotemAssumeSrc[nm] = "pop" and A_TickCount - TotemAssumeAt[nm] < 120000)
				TotemCool[nm] := A_TickCount + 180000
			TotemAssume.Delete(nm)
			TotemAssumeMiss.Delete(nm)
			TotemAssumeSlot.Delete(nm)
			TotemAssumeCnt.Delete(nm)
			TotemAssumeSrc.Delete(nm)
			TotemAssumeAt.Delete(nm)
			}
		}
}

TotemNewUnknownSlot(oldSigs) {
	global TotemTaken, TotemSlotN
	os := (oldSigs = "") ? [] : StrSplit(RTrim(oldSigs, ","), ",")
	pairs := []
	for j, o in os
		{
		k := 1
		while (k <= TotemSlotN)
			{
			d := TotemSigDist(TotemSlotSig(k), o)
			if (d <= 1900)
				pairs.Push({d: d, j: j, k: k})
			k++
			}
		}
	TotemSortByD(pairs)
	usedJ := {}
	usedK := {}
	for i, p in pairs
		{
		if (usedJ.HasKey(p.j) or usedK.HasKey(p.k))
			continue
		usedJ[p.j] := 1
		usedK[p.k] := 1
		}
	k := 1
	while (k <= TotemSlotN)
		{
		if (TotemSlotName(k) = "?" and !usedK.HasKey(k) and !TotemTaken.HasKey(k))
			{
			if (k <= os.MaxIndex() and !usedJ.HasKey(k) and TotemSigDist(TotemSlotSig(k), os[k]) <= 2800)
				{
				k++
				continue
				}
			return k
			}
		k++
		}
	return 0
}

TotemAssumeSet(nm, k) {
	global TotemAssume, TotemAssumeMiss, TotemAssumeSlot, TotemAssumeCnt
	TotemAssume[nm] := TotemSlotSig(k)
	TotemAssumeMiss[nm] := 0
	TotemAssumeSlot[nm] := k
	TotemAssumeCnt[nm] := TotemSlotCount()
}

TotemCoolText() {
	global TotemCool
	txt := ""
	for nm, until in TotemCool
		{
		left := until - A_TickCount
		if (left <= 0)
			continue
		secs := left // 1000
		txt .= (txt = "" ? "" : "     ") . nm . ((nm = "Sundial") ? ": time unchanged (" : ": no effect (") . (secs // 60) . ":" . SubStr("0" . Mod(secs, 60), -1) . ")"
		}
	return txt
}

TotemAssumeText() {
	global TotemAssume
	txt := ""
	for nm, sig in TotemAssume
		{
		if (!TotemHasByName(nm))
			txt .= (txt = "" ? "" : ", ") . nm
		}
	return txt
}

TotemNeedsTime(nm) {
	if (nm = "Day" or nm = "Night")
		return nm
	if (nm = "Aurora" or nm = "Starfall")
		return "Night"
	if (nm = "Eclipse")
		return "Day"
	return ""
}

TotemIsWeather(nm) {
	return (nm = "Tempest" or nm = "Windset" or nm = "Smokescreen")
}

TotemConflict(nm) {
	global TotemSel1, TotemSel2, TotemSel3
	b := TotemNeedsTime(nm)
	if (b = "")
		return false
	for i, sel in [TotemSel1, TotemSel2, TotemSel3]
		{
		a := TotemNeedsTime(sel)
		if (a != "")
			return (a != b)
		}
	return false
}

TotemIsWeatherState(nm) {
	return (nm = "Clearcast" or nm = "Tempest" or nm = "Windset" or nm = "Smokescreen")
}

TotemWeatherConflict(nm) {
	global TotemSel1, TotemSel2, TotemSel3
	if (!TotemIsWeatherState(nm))
		return false
	for i, sel in [TotemSel1, TotemSel2, TotemSel3]
		{
		if (TotemIsWeatherState(sel))
			return (sel != nm)
		}
	return false
}

TotemPickClash(a, b, hard := false) {
	if (a = "" or b = "" or a = "None" or b = "None")
		return false
	if (a = b)
		return true
	ta := TotemNeedsTime(a)
	tb := TotemNeedsTime(b)
	if (ta != "" and tb != "")
		return (ta != tb or (!hard and (a = ta or b = tb)))
	if (TotemIsWeatherState(a) and TotemIsWeatherState(b))
		return true
	ga := TotemGroupOf(a)
	return (ga != "" and ga = TotemGroupOf(b))
}

TotemTimeCovered(v, w1, w2) {
	if (v != "Day" and v != "Night")
		return false
	return ((w1 != v and TotemNeedsTime(w1) = v) or (w2 != v and TotemNeedsTime(w2) = v))
}

TotemSelSanitize() {
	global TotemSel1, TotemSel2, TotemSel3
	if (TotemSel1 = "")
		TotemSel1 := "None"
	if (TotemSel2 = "")
		TotemSel2 := "None"
	if (TotemSel3 = "")
		TotemSel3 := "None"
	if (TotemPickClash(TotemSel1, TotemSel2, true))
		TotemSel2 := "None"
	if (TotemPickClash(TotemSel1, TotemSel3, true) or TotemPickClash(TotemSel2, TotemSel3, true))
		TotemSel3 := "None"
	if (TotemTimeCovered(TotemSel1, TotemSel2, TotemSel3))
		TotemSel1 := "None"
	if (TotemTimeCovered(TotemSel2, TotemSel1, TotemSel3))
		TotemSel2 := "None"
	if (TotemTimeCovered(TotemSel3, TotemSel1, TotemSel2))
		TotemSel3 := "None"
	if (TotemPickClash(TotemSel1, TotemSel2))
		TotemSel2 := "None"
	if (TotemPickClash(TotemSel1, TotemSel3) or TotemPickClash(TotemSel2, TotemSel3))
		TotemSel3 := "None"
}

TotemListsRefresh() {
	global TotemSel1, TotemSel2, TotemSel3, TotemLblH
	if (!IsObject(TotemLblH))
		return
	tlSel := [TotemSel1, TotemSel2, TotemSel3]
	for tlK, tlCur in tlSel
		{
		tlList := ""
		tlPos := 1
		tlN := 0
		for tlI, tlOpt in StrSplit("None|Day|Night|Clearcast|Aurora|Starfall|Eclipse|Tempest|Windset|Smokescreen|Shiny|Sparkling|Mutation", "|")
			{
			tlBad := false
			for tlJ, tlOther in tlSel
				{
				if (tlJ != tlK and TotemPickClash(tlOpt, tlOther))
					tlBad := true
				}
			if (tlBad)
				continue
			tlN++
			tlList .= "|" . tlOpt
			if (tlOpt = tlCur)
				tlPos := tlN
			}
		GuiControl, 1:, TotemSel%tlK%, %tlList%
		GuiControl, 1:Choose, TotemSel%tlK%, %tlPos%
		}
}

WhEsc(t) {
	t := StrReplace(t, "\", "\\")
	t := StrReplace(t, """", "\""")
	t := StrReplace(t, "`r", "")
	t := StrReplace(t, "`n", "\n")
	t := StrReplace(t, "`t", " ")
	return t
}

WhField(nm, val, inline := true) {
	return "{""name"":""" . WhEsc(nm) . """,""value"":""" . WhEsc(val) . """,""inline"":" . (inline ? "true" : "false") . "}"
}

WhStamp() {
	ts := A_NowUTC
	FormatTime, d, %ts%, yyyy-MM-dd
	FormatTime, t, %ts%, HH:mm:ss
	return d . "T" . t . ".000Z"
}

WhBuildJson(title, desc, color, fieldsJson, footer, img := "") {
	j := "{""username"":""DeepFish"",""embeds"":[{"
	j .= """title"":""" . WhEsc(title) . ""","
	if (desc != "")
		j .= """description"":""" . WhEsc(desc) . ""","
	j .= """color"":" . color . ","
	if (fieldsJson != "")
		j .= """fields"":[" . fieldsJson . "],"
	if (img != "")
		j .= """image"":{""url"":""attachment://" . img . """},"
	j .= """footer"":{""text"":""" . WhEsc(footer) . """},"
	j .= """timestamp"":""" . WhStamp() . """"
	j .= "}]}"
	return j
}

WhPost(json) {
	global WebhookURL
	if (WebhookURL = "" or InStr(WebhookURL, "discord") = 0)
		return false
	try
		{
		req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		req.SetTimeouts(4000, 4000, 4000, 6000)
		req.Open("POST", WebhookURL, false)
		req.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
		req.Send(json)
		}
	catch e
		return false
	return true
}

WhTick:
if (!WebhookOn or WebhookURL = "" or !MacroRunning)
	return
if (WebhookSummaryMin >= 1 and (A_TickCount - WhLastSummary) >= (WebhookSummaryMin * 60000))
	{
	WhLastSummary := A_TickCount
	WhEvent("summary")
	}
if (WebhookOnAlert and !WhStalled and WebhookStallMin >= 1)
	{
	WhRef := WhLastCatchTick ? WhLastCatchTick : WhStartTick
	if (WhRef and (A_TickCount - WhRef) >= (WebhookStallMin * 60000))
		{
		WhStalled := true
		WhEvent("stall")
		}
	}
return

;====================================================================================================;

WhSendShot(json, fallback := "") {
	global WebhookURL
	if (WebhookURL = "")
		return false
	cu := A_WinDir . "\System32\curl.exe"
	if (!FileExist(cu))
		return WhSendAsync(fallback != "" ? fallback : json)
	stamp := A_TickCount
	jf := A_Temp . "\deepfish_wh_" . stamp . ".json"
	pf := A_Temp . "\deepfish_shot_" . stamp . ".jpg"
	sf := A_Temp . "\deepfish_shot_" . stamp . ".ps1"
	FileDelete, %jf%
	FileAppend, % json, %jf%, UTF-8-RAW
	if (!FileExist(jf))
		return false
	sw := A_ScreenWidth
	sh := A_ScreenHeight
	tw := sw // 2
	if (tw > 1280)
		tw := 1280
	if (tw < 640)
		tw := 640
	th := Round(sh * tw / sw)
	ps := "Add-Type -AssemblyName System.Drawing`n"
	ps .= "$ErrorActionPreference='SilentlyContinue'`n"
	ps .= "$W=" . sw . "; $H=" . sh . "; $TW=" . tw . "; $TH=" . th . "`n"
	ps .= "$J='" . jf . "'; $P='" . pf . "'; $S='" . sf . "'`n"
	ps .= "$C='" . cu . "'; $U='" . WebhookURL . "'`n"
	ps .= "$b=New-Object System.Drawing.Bitmap $W,$H`n"
	ps .= "$g=[System.Drawing.Graphics]::FromImage($b)`n"
	ps .= "$g.CopyFromScreen(0,0,0,0,$b.Size)`n"
	ps .= "$t=New-Object System.Drawing.Bitmap $TW,$TH`n"
	ps .= "$g2=[System.Drawing.Graphics]::FromImage($t)`n"
	ps .= "$g2.InterpolationMode='HighQualityBicubic'`n"
	ps .= "$g2.DrawImage($b,0,0,$TW,$TH)`n"
	ps .= "$enc=[System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }`n"
	ps .= "$ep=New-Object System.Drawing.Imaging.EncoderParameters 1`n"
	ps .= "$ep.Param[0]=New-Object System.Drawing.Imaging.EncoderParameter -ArgumentList ([System.Drawing.Imaging.Encoder]::Quality), ([long]70)`n"
	ps .= "$t.Save($P,$enc,$ep)`n"
	ps .= "$g.Dispose(); $g2.Dispose(); $b.Dispose(); $t.Dispose()`n"
	ps .= "$ca=@('-s','-m','30','-F',""payload_json=<$J"",'-F',""files[0]=@$P;filename=shot.jpg"",$U)`n"
	ps .= "& $C @ca`n"
	ps .= "Remove-Item $J,$P,$S -Force -ErrorAction SilentlyContinue`n"
	FileDelete, %sf%
	FileAppend, % ps, %sf%, UTF-8-RAW
	if (!FileExist(sf))
		{
		FileDelete, %jf%
		return false
		}
	Run, powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%sf%", , Hide
	return true
}

WhSendAsync(json) {
	global WebhookURL
	if (WebhookURL = "")
		return false
	tf := A_Temp . "\deepfish_wh_" . A_TickCount . ".json"
	FileDelete, %tf%
	FileAppend, % json, %tf%, UTF-8-RAW
	if (!FileExist(tf))
		return false
	cu := A_WinDir . "\System32\curl.exe"
	if (FileExist(cu))
		{
		cmd := A_ComSpec . " /c """"" . cu . """ -s -m 15 -H ""Content-Type: application/json"" --data-binary @""" . tf . """ """ . WebhookURL . """ & del """ . tf . """"""
		Run, %cmd%, , Hide
		return true
		}
	WhPost(json)
	FileDelete, %tf%
	return true
}

WhRuntimeText() {
	global WhStartTick
	if (!WhStartTick)
		return "0h 0m"
	ms := A_TickCount - WhStartTick
	tsec := ms // 1000
	th := tsec // 3600
	tm := Mod(tsec, 3600) // 60
	return th . "h " . tm . "m"
}

WhCommonFields() {
	global WhCatches, WhStartTick, ActiveProfile
	caught := CaughtTotal()
	global TotemAuto, TotemTime, TotemWeather
	ms := WhStartTick ? (A_TickCount - WhStartTick) : 0
	hrs := (ms > 0) ? (ms / 3600000.0) : 0
	rate := (hrs > 0.01) ? Round(caught / hrs) : 0
	f := WhField("Runtime", WhRuntimeText(), true)
	f .= "," . WhField("Fish", caught . "", true)
	f .= "," . WhField("Per hour", rate . "", true)
	f .= "," . WhField("Profile", ActiveProfile, true)
	if (TotemAuto)
		{
		st := (TotemTime = "" ? "?" : TotemTime)
		st .= " / " . (TotemWeather = "" ? "?" : TotemWeather)
		f .= "," . WhField("Server", st, true)
		}
	return f
}

WhEvent(kind, detail := "") {
	global WebhookOn, WebhookURL, WebhookOnAlert, WebhookShot, ActiveProfile
	if (!WebhookOn or WebhookURL = "")
		return
	if (kind = "start")
		j := WhBuildJson("Macro started", "", 3066993, WhCommonFields(), "DeepFish")
	else if (kind = "stop")
		{
		if (!WebhookOnAlert)
			return
		j := WhBuildJson("Macro stopped", "The macro is no longer running.", 15158332, WhCommonFields(), "DeepFish")
		}
	else if (kind = "stall")
		{
		if (!WebhookOnAlert)
			return
		j := WhBuildJson("No fish caught recently", "The macro is running but has not landed a fish for a while.", 15844367, WhCommonFields(), "DeepFish")
		if (WebhookShot)
			{
			cf := WhCommonFields()
			WhSendShot(WhBuildJson("No fish caught recently", "The macro is running but has not landed a fish for a while.", 15844367, cf, "DeepFish", "shot.jpg"), j)
			return
			}
		}
	else if (kind = "summary")
		{
		j := WhBuildJson("Status report", "", 3447003, WhCommonFields(), "DeepFish")
		if (WebhookShot)
			{
			cf := WhCommonFields()
			WhSendShot(WhBuildJson("Status report", "", 3447003, cf, "DeepFish", "shot.jpg"), j)
			return
			}
		}
	else if (kind = "catch")
		j := WhBuildJson("Fish caught", "", 10181046, WhCommonFields(), "DeepFish")
	else if (kind = "totem")
		j := WhBuildJson("Totem used", detail, 15105570, WhCommonFields(), "DeepFish")
	else if (kind = "aquarium")
		j := WhBuildJson("Aquarium", detail, 1752220, WhCommonFields(), "DeepFish")
	else if (kind = "keeper")
		j := WhBuildJson("Keeperbound recharge", detail, 11342935, WhCommonFields(), "DeepFish")
	else
		return
	WhSendAsync(j)
}

TotemReadState() {
	global TotemTime, TotemWeather, TotemEvents, TotemDbg, TotemEvtSigs
	kOk := TotemReadStateAt(0)
	if (kOk and TotemTime != "")
		return true
	if (!kOk)
		return false
	kWeather := TotemWeather
	kEvents := TotemEvents
	kSigs := TotemEvtSigs
	kDbg := TotemDbg
	kTime := ""
	for kI, kThr in [215, 190]
		{
		if (TotemReadStateAt(kThr))
			{
			kOk := true
			if (TotemTime != "")
				{
				kTime := TotemTime
				break
				}
			}
		}
	TotemTime := kTime
	TotemWeather := kWeather
	TotemEvents := kEvents
	TotemEvtSigs := kSigs
	TotemDbg := kDbg
	return kOk
}

TotemReadStateAt(thrOverride := 0) {
	global pTotemBits, TotemW, TotemH
	global TotemTime, TotemWeather, TotemEvents, TotemDbg, TotemEvtSigs
	TotemTime := ""
	TotemWeather := ""
	TotemEvents := ""
	TotemEvtSigs := ""
	TotemDbg := ""
	if (!pTotemBits or TotemW < 24 or TotemH < 12)
		return false
	TotemSoftInit()
	TotemEvtInit()
	hmx := []
	hi := 0
	while (hi < 256)
		{
		hmx[hi] := 0
		hi++
		}
	tbBw := Round(TotemH * 0.5)
	if (tbBw < 4)
		tbBw := 4
	tbN := (TotemW + tbBw - 1) // tbBw
	hb := []
	hi := 0
	while (hi < tbN * 256)
		{
		hb[hi] := 0
		hi++
		}
	tot := TotemW * TotemH
	ty := 0
	while (ty < TotemH)
		{
		roff := ty * TotemW * 4
		boff := 0
		nxt := tbBw
		tx := 0
		while (tx < TotemW)
			{
			if (tx >= nxt)
				{
				boff := boff + 256
				nxt := nxt + tbBw
				}
			pv := NumGet(pTotemBits + 0, roff + (tx*4), "UInt")
			qb := pv & 0xFF
			qg := (pv >> 8) & 0xFF
			qr := (pv >> 16) & 0xFF
			pl := (qr + qg + qb) // 3
			hb[boff + pl] := hb[boff + pl] + 1
			qmx := (qr > qg) ? qr : qg
			if (qb > qmx)
				qmx := qb
			hmx[qmx] := hmx[qmx] + 1
			tx++
			}
		ty++
		}
	need50 := tot // 2
	need97 := (tot * 97) // 100
	acc := 0
	p97 := -1
	hi := 0
	while (hi < 256)
		{
		bi := 0
		while (bi < tbN)
			{
			acc := acc + hb[bi * 256 + hi]
			bi++
			}
		if (acc >= need97)
			{
			p97 := hi
			break
			}
		hi++
		}
	if (p97 < 0)
		p97 := 255
	thrBase := p97
	if (thrBase > 215)
		thrBase := 215
	thrBlk := []
	bi := 0
	while (bi < tbN)
		{
		if (thrOverride > 0)
			{
			thrBlk[bi] := thrOverride
			bi++
			continue
			}
		ba := (bi < 2) ? 0 : bi - 2
		bb := (bi + 2 > tbN - 1) ? tbN - 1 : bi + 2
		ltot := 0
		bj := ba
		while (bj <= bb)
			{
			ltot := ltot + ((bj < tbN - 1) ? tbBw : (TotemW - bj * tbBw)) * TotemH
			bj++
			}
		lneed := ltot // 2
		lacc := 0
		p50l := 255
		hi := 0
		while (hi < 256)
			{
			bj := ba
			while (bj <= bb)
				{
				lacc := lacc + hb[bj * 256 + hi]
				bj++
				}
			if (lacc >= lneed)
				{
				p50l := hi
				break
				}
			hi++
			}
		thr := thrBase
		if (thr < p50l + 40)
			thr := p50l + 40
		if (thr < 150)
			thr := 150
		if (thr > 250)
			thr := 250
		thrBlk[bi] := thr
		bi++
		}
	acc := 0
	p50mx := 255
	hi := 0
	while (hi < 256)
		{
		acc := acc + hmx[hi]
		if (acc >= need50)
			{
			p50mx := hi
			break
			}
		hi++
		}
	colUp := p50mx + 40
	VarSetCapacity(tsMask, tot, 0)
	tsGap := Round(TotemH * 0.075)
	if (tsGap < 2)
		tsGap := 2
	tsMinW := Round(TotemH * 0.2)
	if (tsMinW < 6)
		tsMinW := 6
	tsTrim := Round(TotemH * 0.08)
	if (tsTrim < 2)
		tsTrim := 2
	cnt := []
	ctop := []
	cbot := []
	tx := 0
	while (tx < TotemW)
		{
		cnt[tx] := 0
		ctop[tx] := 9999
		cbot[tx] := -1
		tx++
		}
	ty := 0
	while (ty < TotemH)
		{
		roff := ty * TotemW * 4
		bi := 0
		thr := thrBlk[0]
		nxt := tbBw
		tx := 0
		while (tx < TotemW)
			{
			if (tx >= nxt)
				{
				bi := bi + 1
				thr := thrBlk[bi]
				nxt := nxt + tbBw
				}
			pv := NumGet(pTotemBits + 0, roff + (tx*4), "UInt")
			qb := pv & 0xFF
			qg := (pv >> 8) & 0xFF
			qr := (pv >> 16) & 0xFF
			pl := (qr + qg + qb) // 3
			qmx := (qr > qg) ? qr : qg
			if (qb > qmx)
				qmx := qb
			qmn := (qr < qg) ? qr : qg
			if (qb < qmn)
				qmn := qb
			qs := (qmx > 0) ? ((qmx - qmn) * 100) // qmx : 0
			if (pl >= thr or (qs >= 40 and qmx >= 160 and qmx >= colUp))
				{
				NumPut(1, tsMask, ty * TotemW + tx, "UChar")
				cnt[tx] := cnt[tx] + 1
				if (ty < ctop[tx])
					ctop[tx] := ty
				if (ty > cbot[tx])
					cbot[tx] := ty
				}
			tx++
			}
		ty++
		}
	rs := []
	re := []
	nr := 0
	st := -1
	tx := 0
	while (tx < TotemW)
		{
		if (cnt[tx] >= 2)
			{
			if (st < 0)
				st := tx
			}
		else if (st >= 0)
			{
			nr++
			rs[nr] := st
			re[nr] := tx - 1
			st := -1
			}
		tx++
		}
	if (st >= 0)
		{
		nr++
		rs[nr] := st
		re[nr] := TotemW - 1
		}
	ms := []
	me := []
	nm := 0
	ri := 1
	while (ri <= nr)
		{
		if (nm > 0 and (rs[ri] - me[nm] - 1) <= tsGap)
			me[nm] := re[ri]
		else
			{
			nm++
			ms[nm] := rs[ri]
			me[nm] := re[ri]
			}
		ri++
		}
	keepS := []
	keepE := []
	nk := 0
	mi := 1
	while (mi <= nm)
		{
		if ((me[mi] - ms[mi] + 1) >= tsMinW)
			{
			nk++
			keepS[nk] := ms[mi]
			keepE[nk] := me[mi]
			}
		mi++
		}
	tsA := []
	tsB := []
	tsY0 := []
	tsY1 := []
	tsN := 0
	ki := 1
	while (ki <= nk)
		{
		a := keepS[ki]
		b := keepE[ki]
		gS := -1
		gE := -1
		gN := 0
		bS := -1
		bE := -1
		bN := -1
		ty := 0
		while (ty < TotemH)
			{
			rn := 0
			roff := ty * TotemW
			tx := a
			while (tx <= b)
				{
				rn := rn + NumGet(tsMask, roff + tx, "UChar")
				tx++
				}
			if (rn > 0)
				{
				if (gS >= 0 and ty - gE - 1 > tsTrim)
					{
					if (gN > bN)
						{
						bS := gS
						bE := gE
						bN := gN
						}
					gS := -1
					}
				if (gS < 0)
					{
					gS := ty
					gN := 0
					}
				gE := ty
				gN := gN + rn
				}
			ty++
			}
		if (gS >= 0 and gN > bN)
			{
			bS := gS
			bE := gE
			bN := gN
			}
		if (bS >= 0 and (bE - bS + 1) >= TotemH * 0.35)
			{
			tsN++
			tsA[tsN] := a
			tsB[tsN] := b
			tsY0[tsN] := bS
			tsY1[tsN] := bE
			}
		ki++
		}
	if (tsN < 3)
		return false
	tsHS := tsY1[tsN] - tsY0[tsN] + 1
	tsHT := tsY1[tsN - 1] - tsY0[tsN - 1] + 1
	tsHW := tsY1[tsN - 2] - tsY0[tsN - 2] + 1
	tsArS := (tsB[tsN] - tsA[tsN] + 1) / tsHS
	tsArT := (tsB[tsN - 1] - tsA[tsN - 1] + 1) / tsHT
	tsArW := (tsB[tsN - 2] - tsA[tsN - 2] + 1) / tsHW
	tsHx := (tsHS > tsHT) ? tsHS : tsHT
	if (tsHW > tsHx)
		tsHx := tsHW
	tsHn := (tsHS < tsHT) ? tsHS : tsHT
	if (tsHW < tsHn)
		tsHn := tsHW
	if (tsArS < 0.75 or tsArS > 1.45 or tsArT < 0.5 or tsArT > 1.15 or tsArW < 0.8 or tsArW > 1.9 or tsHx > 2 * tsHn)
		return false
	if (TotemSoftDesc(tsA[tsN - 1], tsB[tsN - 1], tsY0[tsN - 1], tsY1[tsN - 1], tsG, tsAr))
		{
		tsNm := TotemSoftBest(tsG, tsAr, ",Day,Night,", tsD, tsNx)
		TotemSoftBest(tsG, tsAr, ",Clear,Foggy,Windy,Rain,Stormy,", tsWD, tsWN)
		TotemDbg .= tsNm . "(" . tsD . "/" . tsNx . ") "
		if (tsWD <= tsD)
			return false
		if (tsD <= 4000 and tsNx - tsD >= 300)
			TotemTime := tsNm
		}
	TotemWeather := "Unknown"
	if (TotemSoftDesc(tsA[tsN - 2], tsB[tsN - 2], tsY0[tsN - 2], tsY1[tsN - 2], tsG, tsAr))
		{
		tsNm := TotemSoftBest(tsG, tsAr, ",Clear,Foggy,Windy,Rain,Stormy,", tsD, tsNx)
		TotemSoftBest(tsG, tsAr, ",Day,Night,", tsWD, tsWN)
		TotemDbg .= tsNm . "(" . tsD . "/" . tsNx . ") "
		if (tsD < tsWD and tsD <= 2800 and tsNx - tsD >= 300)
			TotemWeather := tsNm
		}
	p4 := (tsA[tsN] + tsB[tsN]) - (tsA[tsN - 2] + tsB[tsN - 2])
	ih := tsY1[tsN - 1] - tsY0[tsN - 1] + 1
	ym := Round(TotemH * 0.1)
	if (ym < 1)
		ym := 1
	if (240 * TotemH <= 100 * p4 and 100 * p4 <= 380 * TotemH)
		{
		half := p4 // 8
		ya := (tsY0[tsN - 1] < tsY0[tsN - 2]) ? tsY0[tsN - 1] : tsY0[tsN - 2]
		ya := ya - ym
		if (ya < 0)
			ya := 0
		yb := (tsY1[tsN - 1] > tsY1[tsN - 2]) ? tsY1[tsN - 1] : tsY1[tsN - 2]
		yb := yb + ym
		if (yb > TotemH - 1)
			yb := TotemH - 1
		k := 1
		Loop
			{
			q := (tsA[tsN - 2] + tsB[tsN - 2]) * 2 - k * p4
			cx := (q + 2) // 4
			x0 := cx - half
			x1 := cx + half
			if (x0 < 0)
				break
			sl := TotemSlotRead(x0, x1, ya, yb, ih, tsGap, 60)
			if (sl.st != "icon")
				{
				TotemDbg .= "slot" . k . ":" . sl.st . " "
				break
				}
			eNm := TotemEvtBest(sl.g, sl.ar, sl.hue, sl.sat, eD, eNx)
			TotemDbg .= eNm . "(" . Round(eD) . "/" . Round(eNx) . ") "
			sg := ""
			gi := 0
			while (gi < 144)
				{
				gv := sl.g[gi]
				if (gv > 999)
					gv := 999
				sg .= SubStr("00" . gv, -2)
				gi++
				}
			TotemEvtSigs .= sl.hue . "/" . sl.sat . "/" . sl.ar . "/" . sg . ","
			if (eD <= 2800 and eNx - eD >= 500)
				TotemEvents .= eNm . ","
			else
				TotemEvents .= "?,"
			k++
			}
		}
	return true
}

TotemSoftInit() {
	global TotemSoft
	if (TotemSoft.MaxIndex() >= 14)
		return
	TotemSoft := []
	TotemSoft.Push({n: "Day", g: "342009070625510605050706131135080514310504271704041373140313140403613102010105126588867622030000000000547927104578050000233700813215120679152237233700792308091481142236000000477012145377030000000000055686877620020000000467060005070000572600000025000009260000181000000000000013430000000000", a: 100})
	TotemSoft.Push({n: "Night", g: "000000000014313842383210000000174255484648656430000133563610000039542000033653110000001756120000236026000000014841000000356615000000036331000000346615000000056230000000266222000000025336000000054649030000002652050000000546482103000046501500000003305352332838656225000000000116273236363013", a: 73})
	TotemSoft.Push({n: "Windy", g: "242216161816113313080706232116121212444753110401181819181312280434290500161820181814091042220100446565656465656553010000162020191919181805000000416363636363636363571400000000000000000000005000345151515050200000004600081310090812500000184100000000002212470000110500000000001033120000000000", a: 121})
	TotemSoft.Push({n: "Rain", g: "120703160015040216000000332509480137200747000000274202531031360452090000105407373011520339280000004527155000461916500000003040045409303406530800001454024321164900462100000248192144024912244300000028390254082734055407000013520242211549004521000003531027370352073234000000331708430034171041", a: 160})
	TotemSoft.Push({n: "Foggy", g: "161413110846602100040602161412115865506836030300140934715102060866110000063070220400010140592000006813050401000008297011007303030302000000003036004824000203000000003435001170322627272525307109000009374441424343400900000007464847474808300000000000151414161600000000000000320060626363150000", a: 105})
	TotemSoft.Push({n: "Clear", g: "191501010100010000000000305408043551462501000000033752102722245537010000010251520500001057130000012566694000000043230000225738245723000034451000512400001757210013425711561100000018581900003431512200000000315704003034315621090707105942013219012850535353525359390100000000000000000002422100", a: 114})
	TotemSoft.Push({n: "Stormy", g: "030202010214160101030201030202105751496323020201030534621101000357060000034657170301010134330000255603000002030219565003562800000357693700002637503300001785861600000347185705005084420000002433001856578386796850504601000000256285670400000000000000013265130000000000000000015210000000000000", a: 110})
	TotemSoft.Push({n: "Stormy", g: "050504030458754801000202040403127344305165000000040555791202000036350000025349010202020006791100027301000100030200446724185700020047614300000070027400010467651700000067005935023170480701002556010142647366635356574600060200050767520000000000050401001657000000000000020404023806000000000000", a: 110})
	TotemSoft.Push({n: "Rain", g: "210501150013040115000000562307490037190847000000474000521030340452090000175306342910520239270000004424144900451916500000002940015408293305520900001354014220154900462100000149182144024912234300000029380254072733055507000013520143201448004620000002541027380250063235000000321807430033171041", a: 153})
	TotemSoft.Push({n: "Night", g: "000000000005173138383523000000083750494240475850000014463314030020504911023254250000000752481000205340030000002254210000325926000000003150060000336026000000003150060000255637010000002552130000054156180000001155390400000530481905000028554407000000174851412927415846000000000210182833343322", a: 68})
	TotemSoft.Push({n: "Day", g: "000000000044520000000000262300000027330000012723445303001017170900086340000206507570707250100301000557681703012073540100051786300000000023760315031482350000000131730309000240743915134282410000020701296575766329031003566103000002020000096950100800000040480000000909000000000030370000000000", a: 75})
	TotemSoft.Push({n: "Foggy", g: "000100010645533502000000000001116051425552030000000135622900000147350000004548150100000019663702136202000000000004194841146201000000000000000961006017000000000000001857002562393635353636376028000011323435343434341700000028666667676739361100000000170723232322140000000000351445454545290000", a: 100})
	TotemSoft.Push({n: "Clear", g: "102900000000000000000000135920002652523708000000001858191922173854060000000033641900000143330000002059635906000022450000135936164745020011622502373600000347440202285336402900000003464302001256314700000000065829001355115943272424245063171330000933383838383840581700000000000000000000173700", a: 114})
	TotemSoft.Push({n: "Windy", g: "010101000000001342120000010100000000135743560500000000000000323701471600051515151515141417551200176464646564646463480000062322212121212121080300155454545454545354535724000000000000000000001553166363636363602800001252000000000000235500005433000000003439395000002302000000000329300800000000", a: 116})
}

TotemSoftDesc(a, b, y0, y1, ByRef tsG, ByRef tsAr) {
	global pTotemBits, TotemW, TotemH
	if (a > 0)
		a := a - 1
	if (b < TotemW - 1)
		b := b + 1
	if (y0 > 0)
		y0 := y0 - 1
	if (y1 < TotemH - 1)
		y1 := y1 + 1
	bw := b - a + 1
	bh := y1 - y0 + 1
	sh := []
	hi := 0
	while (hi < 256)
		{
		sh[hi] := 0
		hi++
		}
	yy := y0
	while (yy <= y1)
		{
		xx := a
		while (xx <= b)
			{
			pv := NumGet(pTotemBits + 0, (yy * TotemW + xx) * 4, "UInt")
			v := pv & 0xFF
			if (((pv >> 8) & 0xFF) > v)
				v := (pv >> 8) & 0xFF
			if (((pv >> 16) & 0xFF) > v)
				v := (pv >> 16) & 0xFF
			sh[v] := sh[v] + 1
			xx++
			}
		yy++
		}
	sn := bw * bh
	acc := 0
	bg := -1
	pk := 255
	hi := 0
	while (hi < 256)
		{
		acc := acc + sh[hi]
		if (bg < 0 and acc * 100 >= 40 * sn)
			bg := hi
		if (acc * 100 >= 98 * sn)
			{
			pk := hi
			break
			}
		hi++
		}
	if (bg < 0 or pk - bg < 20)
		return false
	rng := pk - bg
	tsG := []
	gsum := 0
	gi := 0
	while (gi < 12)
		{
		gj := 0
		while (gj < 12)
			{
			sy0 := (bh * gi) // 12
			sy1 := (bh * (gi + 1)) // 12
			if (sy1 <= sy0)
				sy1 := sy0 + 1
			sx0 := (bw * gj) // 12
			sx1 := (bw * (gj + 1)) // 12
			if (sx1 <= sx0)
				sx1 := sx0 + 1
			ct := 0.0
			cn := 0
			yy := sy0
			while (yy < sy1)
				{
				xx := sx0
				while (xx < sx1)
					{
					pv := NumGet(pTotemBits + 0, ((y0 + yy) * TotemW + a + xx) * 4, "UInt")
					v := pv & 0xFF
					if (((pv >> 8) & 0xFF) > v)
						v := (pv >> 8) & 0xFF
					if (((pv >> 16) & 0xFF) > v)
						v := (pv >> 16) & 0xFF
					fv := (v - bg) / rng
					if (fv > 1)
						fv := 1
					if (fv > 0)
						ct := ct + fv
					cn++
					xx++
					}
				yy++
				}
			gv := Floor(ct / cn * 100)
			tsG[gi * 12 + gj] := gv
			gsum := gsum + gv
			gj++
			}
		gi++
		}
	if (gsum < 1)
		return false
	gmean := gsum / 144
	gi := 0
	while (gi < 144)
		{
		tsG[gi] := Round(tsG[gi] / gmean * 20)
		gi++
		}
	tsAr := bw / bh
	return true
}

TotemSoftBest(tsG, tsAr, names, ByRef bD, ByRef nD) {
	global TotemSoft
	per := {}
	for sI, st in TotemSoft
		{
		if (!InStr(names, "," . st.n . ","))
			continue
		d := 0
		gi := 0
		while (gi < 144)
			{
			dv := tsG[gi] - (SubStr(st.g, gi * 2 + 1, 2) + 0)
			d := d + ((dv < 0) ? 0 - dv : dv)
			gi++
			}
		d := d + Abs(Round(tsAr * 100) - st.a) * 8
		if (!per.HasKey(st.n) or d < per[st.n])
			per[st.n] := d
		}
	bN := ""
	bD := 999999
	nD := 999999
	for pn, pd in per
		{
		if (pd < bD)
			{
			nD := bD
			bD := pd
			bN := pn
			}
		else if (pd < nD)
			nD := pd
		}
	return bN
}

TotemHue(r, g, b) {
	mx := (r > g) ? r : g
	if (b > mx)
		mx := b
	mn := (r < g) ? r : g
	if (b < mn)
		mn := b
	dl := mx - mn
	if (dl < 1)
		return -1
	if (mx = r)
		h := 60 * (((g - b) / dl) + 0)
	else if (mx = g)
		h := 60 * (((b - r) / dl) + 2)
	else
		h := 60 * (((r - g) / dl) + 4)
	h := Round(h)
	if (h < 0)
		h := h + 360
	if (h >= 360)
		h := h - 360
	return h
}

TotemEvtInit() {
	global TotemEvt
	if (TotemEvt.MaxIndex() >= 99)
		return
	TotemEvt := []
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000003000000000004000000000000000003056049000006062099057004000000027076062004000063093044104054000033104075000000014070013000025086067082039003000000000000000000000014061006000000000000000000000000000000000000000000000000000051093019000000000000000000000000019067033089035000000001037053053023000000000040105032000042101047000000000000000000040088057085024000000000000000000000000018056006000000000000", a: 105, h: 146, s: 38})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000000000000000000000000000000000000003005000000000000000000000000000000019028016000004007000000000050063054016058063024000000000000041063063063050014059059008000000012063063064064063038041063053000002018063064065065064051040064058000005001059064065065063019050064030000000000014054063059026038063039000000000000000000000000037057028000000000000000000000000000000000000000000005000000000000000000001003000000000000000", a: 100, h: 29, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000001024000000000000000000000000000000025069000000000000000000000000000000065088020000000000000000000000000018066038052000000000000015036051059073036006067061061049025000054089012000000000000003059083015000000049054000000000000000075010000000000004079001000000000074045000000000000000070000014031001058040000000000000002087085081067085087043000000000000022085056014000041081067000000000000013011000000000000000028001000", a: 105, h: 128, s: 28})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000019000000000000000000000000000000026067000000000000000000000000000000057082014000000000000000000000000012072054041000000000000017041042052076047009073061041042026000033080028005000000001009074066010000000041058000000000000031079001000000000002069020000000009080027000000000000000065031020034019080023000000000000003080076077070074083036000000000000007081062019002046080052000000000000014018000000000000004028000000", a: 105, h: 46, s: 41})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000000027062053000000000000000000004043068055056102035000000000000009066029000034068010000000000000000068011000000067000000000000000000012064000000036022000000000000021095054046096017062000000000000000020066071045058019049000000000000000017051000000075022028000000000000034092006000000027097028000000000000002072100009031097082036000000000000000000020092076008000000000000000000000000000031028000000000000000000000", a: 100, h: 293, s: 23})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000011000000008014000000000000000002035073000017072084025000000000004049082033050079052042075024000015067066018000070021000000035084061080048003000000001000000000000037076028000000000000000019010000000000000000000000000000051086074008000000000000000000000000066033053072014000000000015042044043000000002054072005000018080054018016000000000002052071047074036001000000000000000000001036058014000000000000", a: 94, h: 147, s: 40})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000009000000000000000000000000000000000007000000000000000000000000000000016021006000012017000000015038049034020044055035003000000020056057057057053012052056030000000050057057057057057038037057046000000053057057058057057046036057050000009035057057057057057024046057038000000004032054057052024025056051010000000000000001010001030048031002006002000000000000000000000000000000001006000000000000000000000012000000000000000", a: 94, h: 28, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000027027000000000000000000000000000002062062002000000000000000000000000022074074021000000000000000000000002052032042052002000000000033042065071059002002059070066057033056074053004000000000000011057074045001017058026000000000000019056017001000000029069000000000000069029000000000000028050003023023003049028000000000000036070063054053063069036000000000000053066026000000026066055000000000000021005000000000000005026002000", a: 94, h: 131, s: 30})
	TotemEvt.Push({n: "Shiny", g: "000000000000000011036000000000000000000000000000000053069012000000000000000000000000008070070031000000000000000000000002036056036054007000000000040041041058066020000056065045041039037065062018014000000008016051070049000007053045003000000000020060023000000000011069013000000000053033000000000000011068017020030008051033000000000000028070062060051062065049000000000000033066038005000023058058002000000000023010000000000000002023006000", a: 94, h: 46, s: 41})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000003030062062026000000000000000009045062045042090048000000000000010084029000004068007000000000000005064011000003069018000000000000000048037000000034035000000000000044072035037083030057001000000000000041059057027083014050000000000000000049035000002088022022000000000000076064004000000016079025000000000000043073084006046082065036000000000000000000025075060002000000000000000000000000000044015000000000000000000000", a: 94, h: 285, s: 26})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000022000000002010000000000000000008060070000017067088038000000000022072061013030088055024084035001035086046000000058038000000027088074079027000000000000000000000000028060013000000000000000010017000000000000000000000000000025081087016000000000000000000000000060047038085023000000001033053053038000000000030086014000044084027005003000000000000043084067082013000000000000000000000000039056010000000000000", a: 103, h: 148, s: 41})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000006007000000000000000000000000000000003004000000000000000000000000006000019027015000018003000000014052060053023051059034000000000007056060060060054021059059013000000033060061061061060026053060034000006035060061061061061030052061036000009016059061061061059018059061020000000000023051060054028044059039000000000000000000004000024035019000015001000000000000000000000000000000001000000000000000000000006007000000000000000", a: 100, h: 28, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000028029000000000000000000000000000000060060000000000000000000000000000019078078019000000000000000000000002053026037053002001000000036046069069058006006058071073057031025072068004000000000000011070072019000001056048000000000000036055001000000000017075005000000005075017000000000000016063004028027003062015000000000000027079076047047075079027000000000000041073026000000026073044000000000000019010000000000000009027000000", a: 103, h: 130, s: 30})
	TotemEvt.Push({n: "Shiny", g: "000000000000000015033000000000000000000000000000000055068008000000000000000000000000007073073025000000000000000000000003042054036055007000000000042051051061070017003062066051051042014047074017007000000005012068063020000000044061004000000000041058004000000000003071018000000001070018000000000000003072025027033014067019000000000000017075070055044069073033000000000000022073039000000023068045000000000000020015000000000000007026000000", a: 103, h: 47, s: 41})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000016056070064021000000000000000012058069038048087026000000000000028064021000037050002000000000000015069000000023058000000000000001000063021001000057006000000000000053083045056092023055000000000000000043050056016074042026000000000000000052032000011082033010000000000000079064010000003036083013000000000000025052074011065060048015000000000000000000026085053000000000000000000000000000000054011000000000000000000000", a: 103, h: 285, s: 26})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000004029000000012019000000000000000016069057001033083087034000000001031081053005047081039031083033007048080037000000051015000000024085082064013000000000000000000000000025048001000000000000000022014000000000000000000000000000050086083018000000000000000000000000062025043080018000000003045064064043000000000042080016003059070019006004000000000000041082080064006000000000000000000000000036039004000000000000", a: 102, h: 148, s: 42})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000001011000000000000000000000000000000001008000000000000000000000000000000016023008000016007000000009039051042023048057031000000000004051059059059055022057058020000000029059059059059059033048059042000002033059059059059059039046059047000017013058059059059059025054059030000000000025056059058033033058050003000000000000004014006022045029003010001000000000000000000000000000000001002000000000000000000002014000000000000000", a: 100, h: 28, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000028028000000000000000000000000000000059059000000000000000000000000000015079079015000000000000000000007010057031040057010008003000042059072059048005005048065076066037017072067004000000000000007068072014000003057050000000000000040056003000000000015074002000000002073015000000000000015059002033033002059015000000000000032080075046045074079031000000000000048065019000000018065054000000000000019004000000000000004025000000", a: 102, h: 130, s: 31})
	TotemEvt.Push({n: "Shiny", g: "000000000000000025025000000000000000000000000000000063062000000000000000000000000000013073072013000000000000000000000010052046045050009000000000055062061064064010010062064061061046012055067005000000000000012070059012000004055051002000000002050053004000000000007071008000000007070006000000000000012070018037036016068010000000000000031073068047046067073028000000000000040063023000000022061046000000000000024006000000000000005023000000", a: 102, h: 47, s: 42})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000023059068067025000000000000000023068055025048075018000000000000029065011000043051000000000000000022072003000024055000000000000013007057015017002065006000000000000063091044065093036052000000000000000052041047012070050018000000000000006067019000004075038003000000000000082053013000004029085011000000000000022046076017066058042011000000000000000000022092048000000000000000000000000000000039005000000000000000000000", a: 102, h: 283, s: 27})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000001000000000015002000000000000001049044000002042097071003000000011084076000000063075044073060001032080059008000029061000000000076090098029000000000000000000000000015063010000000000000000000000000000000000000000000000000010065097050000000000000000000000000036082012095037000000000021046046021000001000020098047000042088045029014000000000000000096088109023000000000000000000000000022062013000000000000", a: 106, h: 145, s: 33})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000000000000000000009000000000006015001000027035021000000000000023036036036028009037037032000000022036036036037037014032037038012000036037037037037037021015037039018006037037037037037037029007038039019005036036036036037037029006037038019000036036036037037037022014037038018000022037037037038038014034038039011000000022037038037029009038039033000000000000005012000000028037022000000000000000000000000000000000000000008", a: 125, h: 28, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000001020000000000000000000000000000000022063000000000000000000000000000000051087016000000000000000000000002015058042066008000000000014043065076085037001073089079069028003061091032000000000000008067093022000000031068000000000000019089017000000000000058015000000000057032000000000000000053000000008000047019000000000000000072067063056068084055000000000000000091059000000007085097000000000000000023000000000000008038008000", a: 106, h: 126, s: 25})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000016000000000000000000000000000000025063000000000000000000000000000000044084003000000000000000000000000015060045055007000000000025060062065082049007081080060060036000042085046010004000005018083076013000000025069000000000000032083008000000000000048044000000000069007000000000000000045042000012000068000000000000000000064080071059075087031000000000000000070069009000021086063000000000000000027000000000000010038000000", a: 106, h: 45, s: 39})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000000000058067030000000000000000000024053055048083069000000000000000062084004000052033000000000000000050041000000030046000000000000000000064000000000095000000000000000085060052074095046028000000000000000075023052016080051000000000000000013062000000031083030000000000000041106023000000000025063000000000000032053057065018072050049000000000000000000000085089000000000000000000000000000000007043000000000000000000000", a: 94, h: 296, s: 20})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000018000000000009000000000000000008067056000000039093038000000000006071073008008063071037077037000031081043000000033050004000014098091085012000000000000000000000000024082014000000000000000000000000000000000000000000000000016066092034000000000000000000000000041064027097033000000000038062063037000000000021092013000038101033016008000000000000047093056098017000000000000000000000000044075018000000000000", a: 107, h: 147, s: 36})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000000010000000000000000000000000000000000000000000000001000000000000004000012036023003000009000000029048050045013026052046008000000028051051051051051009045052041000000048051051052052052028025053052004000048051051051051052035024053052011000041051051052052053021034053051000000010049052053053038008052053024000000000005023027020008045052025000000000000000000000000004011000000000010000000000000000000000007000000000000", a: 92, h: 28, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000016022000000000000000000000000000000040059000000000000000000000000000000068083017000000000000000000000000013058057053000000000000003011031041069031012078050036027006020075082021013001000009027085092039000005053036000000000000020072017000000000009080011000000000066012000000000000001081007000000000063000000000000000003083028062074035070004000000000000021091087033018079096036000000000000029046008000000000040060000000", a: 108, h: 128, s: 27})
	TotemEvt.Push({n: "Shiny", g: "000000000000000010031000000000000000000000000000000045071007000000000000000000000000002072078023000000000000000000000001029059031051004000000000031061063064073017000061073063066039003039079019000000000000005073075010000000040057003000000000026063004000000000001060024000000000079013000000000000000060027023039008077011000000000000003076074070053076084024000000000000006080055004000035084038000000000000012026001000000000010025000000", a: 107, h: 47, s: 39})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000009051067065021000000000000000006053079039042092029000000000000000065032002021066007000000000000006068022000005054000000000000000010047040006000056018000000000000023091040034091021075000000000000000019073073049055038038000000000000000031046000000059037011000000000000059086001000000013088012000000000000027064081012032082061024000000000000000000016079080004000000000000000000000000000047027000000000000000000000", a: 104, h: 289, s: 22})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000012037000000009046005000000000000041085028000026076081061003000004058081023000026084042007068063013067065008000000021020000000007076097051002000000000000000000000000008034001000000000000000015037002000000000000000000000000032091091050000000000000000000000000036038010082032000000004065080082045000000000018092030002071069004000000000000000000028096090071001000000000000000000000000024051003000000000000", a: 108, h: 148, s: 37})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000016000000000000000000000000000000000004000000000000000000000000000000014025016000001013000000012042053042014035056047005000000011054056056057054011041058040000000044057056057057057041023059057003000047056056056056057047020058057006007023057057057057058023034059049000000000029056058057028017057058016000000000000006016006018046036011000005000000000000000000000000000000000004000000000000000000000016000000000000000", a: 97, h: 28, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000020023000000000000000000000000000000045056000000000000000000000000000002067076013000000000000000000000000025042038051001000000000026047063061060016007056071072063035012067079012000000000000008068081022000004047048000000000000023065013000000000001072021000000000081022000000000000000071007012015000065021000000000000004079058065066063081031000000000000022083053005001038088057000000000000024023000000000000013049001000", a: 106, h: 130, s: 29})
	TotemEvt.Push({n: "Shiny", g: "000000000000000012028000000000000000000000000000000052068004000000000000000000000000005072077018000000000000000000000002036055034046002000000000030055057061074021005069068056059036005047080025003000000000018082072009000000035054002000000001052057004000000000000062018000000013082004000000000000000058014013023012082000000000000000000075068073067074088016000000000000001081053006001047088032000000000000012023000000000000016028000000", a: 105, h: 46, s: 40})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000021060071068027000000000000000015068064032041083023000000000000007066012000034058002000000000000003074014000017065001000000000003008035047005000064013000000000000039096048038090027057000000000000000031071050037054044022000000000000000038054000000065037005000000000000052077002000000020076003000000000000040073077023024076070018000000000000000000007082075004000000000000000000000000000041031000000000000000000000", a: 103, h: 288, s: 22})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000013029000000006034004000000000000033080030000014071085059001000001043083023000013079051014071052010060073017000000024028000000007083099061004000000000000000000000000014041000000000000000000008025000000000000000000000000000021083092048000000000000000000000000034049019087033000000003060083083040000000000020089027003069075018013006000000000000028095090076004000000000000000000000000033052004000000000000", a: 109, h: 149, s: 40})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000002011000000000000000000000000000000000001000000000000000000000001004000018029016000009004000000019049055046013040058039001000000019056057057057055014054059023000000043057057057058058030041060041000002044057057057057058033039060042000012026058058058059058016052060029000000001032057059057023032060052003000000000000006015004021043030004007001000000000000000000000000000000001002000000000000000000002012000000000000000", a: 100, h: 28, s: 74})
	TotemEvt.Push({n: "Mutation", g: "000000000000000014023000000000000000000000000000000040055000000000000000000000000000004070077010000000000000000000000000031049045041000000000000020038053054064018008065062058049026011074077007000000000000013074084023000012062025000000000000012069021000000000010074005000000005077027000000000000000069002000003003074017000000000000004077043065069049080023000000000000027085062013007062092050000000000000034035002000000002035060000000", a: 108, h: 130, s: 29})
	TotemEvt.Push({n: "Shiny", g: "000000000000000010019000000000000000000000000000000048061000000000000000000000000000003068076010000000000000000000000003031053041044005000000000031059059061073024010073069062064038004043077027009000000007024081059009000000038059003000000001050052001000000000002063025000000012076003000000000000000060020016023010074000000000000000004074067068065070084013000000000000008080052005001045086028000000000000020031000000000000021033000000", a: 109, h: 47, s: 40})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000015056068060018000000000000000018060065036053079024000000000000012077014000040056000000000000000008075009000018058000000000000002003049037002000062010000000000000038090046046092022060000000000000000029062048024067042029000000000000000046042000000080034010000000000000058079009000000026087013000000000000024060081016048076058020000000000000000000016087066000000000000000000000000000000042018000000000000000000000", a: 102, h: 285, s: 24})
	TotemEvt.Push({n: "Aurora", g: "000000000003000000000000000002081029000005051088046003000000020067051000000054080034098045000027097062000000014063010000020076060073032001000000000000000000000023091011000000000000000000000000000000009000000000000000000020072002000000000000000000000000013080078055000000000000000000000000012033000083062000000003066098097038000000000018085052010065068020000000000000000000000087088068000000000000000000000000000018053006000000000000", a: 117, h: 121, s: 24})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000000000000000007000000000000000000004035033002000000000000010035046046032011048045017000000000041048049049049020034050050003000000048049049049050028009050051018000009050051051051051040004051052023000000051052052052052033012052053019000000044053053053053023037053053003000000011039053053037015054050019000000000000000000000005046040003000000000000000000000000000000000000000005000000000000000000000000000000000000000", a: 119, h: 28, s: 75})
	TotemEvt.Push({n: "Mutation", g: "000000000000000017039000000000000000000000000000000048055016000000000000000000000000014049021045000000000000015034047053067028001062057057046025000071084014000000000000003066088028000015066030000000000000000061041000000000009077000000000000064051000000000000000076002000000000075039000000000000000071000027049004056043000000000000010093091055028083094057000000000000026087024000000013079077000000000000014011000000000000000029001000", a: 117, h: 102, s: 27})
	TotemEvt.Push({n: "Shiny", g: "000000000000000023045000000000000000000000000000000042052010000000000000000000000000008056024034000000000000016038039047069039005067056040040025000056078028012000000002013075078017000003056039000000000000014070021000000000004072018000000006077033000000000000000060024000000009079017000000000000000069036038056026079028000000000000003083082055031076086041000000000000010083040000000020078061000000000000015018000000000000004028000000", a: 117, h: 40, s: 46})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000016081041000000042000000000000000038053012000011022000000000000000029057000000000032000000000000000006084014000000058012000000000018100032015042095028065000000000000021107072074057082054010000000000000000101000000035070050000000000000000061044000000013074043000000000000067088020005000006038091000000000000003035045064017074043037000000000000000000000064107029000000000000000000000000000016060000000000000000000000", a: 100, h: 330, s: 32})
	TotemEvt.Push({n: "Aurora", g: "000000007010000000000000000004055058000013072073007000000000005058073009035075053055073015000018071061010000081024000000053075057087035000000000004000000000001047067014000000000000000000000000000000004000000000000000003039017000000000000000000000000000070079081026000000000000000000000000045004033082018000000000054082082063000000000038080023011059062016003000000000000000039080079068005000000000000000000000000036039004000000000000", a: 107, h: 133, s: 30})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000000000000001004000000000000000000018030014000006002000000015042046034009038048029000000000015047048048048040009047049020000000043049050050050049020036051036000000047051051051051050026034052043000014045052052052052051021038052037000000016052054054054045011051053021000000000016048054040012046054033000000000000000000000000024038018000007000000000000000000000000000000000000004000000000000000000005008000000000000000", a: 111, h: 28, s: 75})
	TotemEvt.Push({n: "Mutation", g: "000000000000000023038000000000000000000000000000000046053010000000000000000000000000022046034049003000000000015023047054066026007063059050043017043073072022011001000006018061076052000033074023000000000000002058053004000000029064001000000000033063003000000000000071004000000000049036000000000000000065000028039005038041000000000000022083079048033073081064000000000000043073019000000005054081007000000000025009000000000000003028011000", a: 107, h: 112, s: 26})
	TotemEvt.Push({n: "Shiny", g: "000000000000000038038000000000000000000000000000003050050002000000000000000000000001032041041031000000000000032032032052067020020067051033033031042067064025021001001019030067070034000031067018000000000000017067030000000002044059000000000000057041000000000000005069000000000000067002000000000000015069015042041013067012000000000000037076070041040068075034000000000000051067016000000016065057000000000001032008000000000000008031001000", a: 107, h: 41, s: 46})
	TotemEvt.Push({n: "Starfall", g: "000000000000000002044076034002014048000000000000000046051007000016040000000000000000044044000000023034000000000000000028075003000000053000000000000029056033020051044024039000000000000044081085077059036071016000000000000021051012008049026074000000000000021066025000000033061036000000000000097061018000000013063086002000000000021041062036032069040037003000000000000000012095091005000000000000000000000000000037034000000000000000000000", a: 97, h: 322, s: 30})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000001026062000000037048003000000000000040085034006053082083047000000003050079021000069062016011069047025063060014000000019002000000010078087036001000000000000000000000000011027000000000000000000023014000000000000000000000000000061084080023000000000000000000000000049011032084022000000003054078077055000000000040078010001055073014000000000000000000051080074073007000000000000000000000003046048007000000000000", a: 105, h: 136, s: 31})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000008000000000000000000000000000000000000000000002006000000000005016008016044032005006002000000018050053052027029054046003000000008052054054054054013049055027000000030056056056056056033033056047000007029057057058058058033035058046000000009056059059059058015052059027000000000019057060059030033060051002000000000000006018010021052038007005002000000000000000000000000000000002005000000000000000000001012000000000000000", a: 105, h: 28, s: 75})
	TotemEvt.Push({n: "Mutation", g: "000000000000000036058000000000000000000000000000001060068012000000000000000000000000018063062036000000000000003006022028054023009060031025018003051072068034020000000015033070075057006049063008000000000000000050060012000001041055002000000000027055005000000000011071011000000000062028000000000000011066009041051012045030000000000000025080077047035073078045000000000000039074030000000016066062000000000000018011000000000000005028002000", a: 105, h: 109, s: 27})
	TotemEvt.Push({n: "Shiny", g: "000000000000001044044000000000000000000000000000007063064007000000000000000000000000023061061023000000000000013013013026055025024054025013013011054067064042033001001032046068070044003040061006000000000000007062043004000001046052002000000001050043000000000000010068007000000007067009000000000000017069023049049020067016000000000000032074071045044070073031000000000000038069025000000025068042000000000000024009000000000000007023000000", a: 105, h: 42, s: 45})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000020065067057090042000000000000002056058013003059024000000000000000048034000001061021000000000000000033049000000035030000000000000026029044014048007057000000000000000052088064067082033043000000000000000036043038013070042022000000000000016064021000007070043006000000000000094058021000009033089021000000000000019044071014067053040012000000000000000000025086050000000000000000000000000000001053011000000000000000000000", a: 105, h: 319, s: 30})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000000000000000000000000000000000000023056000000028073025000000000006054079023005061093062096016000012090071000000038073018000036100066089038002000000000000000000000024089015000000000000000000000000000000000000000000000000028070098038000000000000000000000000040066030100035000000000041070069037000000000015081036006056078025010006000000000000020111106079000000000000000000000000000021046002000000000000", a: 100, h: 150, s: 37})
	TotemEvt.Push({n: "Eclipse", g: "000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000010003000000010000000000009035035013035064030000000000000028062067069068035049067046000000000058060063066066065028065067007000001062062065068068068033067070017010002046066069071072056039070062000000000002036064066046013066061012000000000000000001000000028024002000009000000000000000000000007000000000000000000000000000000000007000000000000000", a: 93, h: 28, s: 73})
	TotemEvt.Push({n: "Mutation", g: "000000000000000003004000000000000000000000000000000035054000000000000000000000000000000064084012000000000000000000000000017066067062000000000000023042058061073025010071062067054030009074084005000000000000007090094028000005061043000000000000021081019000001000008092017000000000073014000000000000002084000024033002059005000000000000016090079051043076093030000000000000039082016000000002065072000000000000011001000000000000001020000000", a: 97, h: 132, s: 27})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000008000000000000000000000000000000031073001000000000000000000000000001074086023000000000000000000000000024078058052000000000000027048049055081034004076060049048032003043085024001000000000007083081013000000048069005000000000030074006000000000003072031000000001088019000000000000000068033029047011084015000000000000005081080053038074091034000000000000020086025000000007066054000000000000008007000000000000000010000000", a: 100, h: 45, s: 39})
	TotemEvt.Push({n: "Starfall", g: "000000000000000000000000005021016000000000000000000000009059089073111054000000000000000049055023015063034000000000000000067036000000064000000000000000006046066005000049028000000000000022095035034099024082000000000000000018080080057064048048000000000000006035049000000071048016000000000000058091002000000018100016000000000000013040062033049060042016000000000000000000007105080000000000000000000000000000000025013000000000000000000000", a: 97, h: 285, s: 26})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000007028000000010029000000000000000030079034000011076088035000000000043085035000026078040025083027006056079016000000045028000000023078075072011000000000000000000000000033044001000000000000000000007000000000000000000000000000010070078007000000000000000000000000051050056073010000000000034063063032009000005064074007000039085061063032000000000005063059054085021000000000000000000000002055056007000000000000", a: 108, h: 140, s: 44})
	TotemEvt.Push({n: "Shiny", g: "000000000000000002020000000000000000000000000000000029054000000000000000000000000000000066079009000000000000000000000000021065051037000000000000026036042048076030005076052044044031023071073027025000000019031069077034000014065032000000000000024073031000000000005063018000000014078019000000000000000060003017031003079012000000000000003069042071071048076026000000000000025073052009001045075051000000000000029021000000000000019043000000", a: 100, h: 49, s: 39})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000019000000000005000000000000000000053063000008063091025000000000019074059006030085042019083019000038094032000000059038000000039082059085027000000000001000000000000038061011000000000000000000006000000000000000000000000000010071086000000000000000000000000000057044052073017000000000031066068045000000000052073011000040097056052034000000000000061062037091019000000000000000000000004056073012000000000000", a: 104, h: 139, s: 43})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000026000000000000000000000000000000032063000000000000000000000000000002076088016000000000000000000000000024069051046000000000000026032037042072021002072052040041028016079075015009000000009018071088030000010070021000000000000007073032000000000013078020000000003083031000000000000000074013001014000082019000000000000009080043073072048078033000000000000028083053000000034084058000000000000031019000000000000010034000000", a: 100, h: 50, s: 39})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000040000000017047006000000000000039074025000007092098062000000000051099029000005073028002067039000055066016000000015019000000000088092076000000000000000000000000000020045003000000000000000000005000000000000000000000000000000066085025000000000000000000000000027045038100031000000000042102102051000000000037079014000038079050051025000000000000033073061088001000000000000000000000000056066014000000000000", a: 111, h: 141, s: 45})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000044000000000000000000000000000000052081000000000000000000000000000001086086033000000000000000000000000034052036055000000000000000000000045077000000065056007000000070078059039034000000021042057081071000032059026000000000000003059038005000000028071005000000000086039000000000000023070000011027000048041000000000000038060029078077046038045000000000000043077049010003037075075000000000000037000000000000000000032000000", a: 89, h: 50, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000001050000000015053014000000000000013057052002027080069076015000002034073051000031073022002047063008054082026000000018007000000000046088062010000000000000000000000000005029002000000000000000014029003000000000000000000000000026080083049000000000000000000000000029018016075052002000000027089099098000000000019079041000041086047033033000000000000014074071078023000000000000000000000000021063010000000000000", a: 106, h: 130, s: 37})
	TotemEvt.Push({n: "Shiny", g: "000000000000000015005000000000000000000000000000000036024000000000000000000000000000000055048000000000000000000000000000018041046019000000000000027034032043062020026066045037033025029065058015017000000015019063069022000008067045000000000000048066011000000000007079020000000023084007000000000000014079004024015006086014000000000000029083049078082052083032000000000000054084059006010061086057000000000000047021000000000000020051000000", a: 100, h: 47, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000048000000014038006000000000000013047065000001077092050000000000008068077004036078027008064051003036080029000000019002000000000053093071009000000000000000000000000013045004000000000000000000001000000000000000000000000000024074083012000000000000000000000000034015021088035000000000025095105104000000000046087025000023082058052051000000000000044073038091042000000000000000000000000034072016000000000000", a: 104, h: 129, s: 36})
	TotemEvt.Push({n: "Shiny", g: "000000000000000005025000000000000000000000000000000026053000000000000000000000000000004059058015000000000000000000000000039035005041000000000000040041038055069006000058060042041042028064063002001000000001005046075034000002065038000000000000035080015000000000004075000000000003089024000000000000000062000023039003078031000000000000017082068072071074080058000000000000044088042000000037091089000000000000047016000000000000011047007000", a: 96, h: 47, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000033000000000038017000000000000000040062000000081098096014000000001066080000005072044008040074007036080048005000018022000000000032092096028000000000000000000000000000043011000000000000000000002000000000000000000000000000000063087050000000000000000000000000015038000083057000000000000076103102000000000018084055000018071066052051000000000000000082064100044000000000000000000000000013069029000000000000", a: 106, h: 130, s: 37})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000008000000000000000000000000000000024065000000000000000000000000000000068063019000000000000000000000000028039028042000000000000000000000035066000000057046000000000074075056039032000000018037055076066000031061024000000000000000061040004000000031089000000000000088045000000000000025085000007029000056047000000000000044091036087096064036051000000000000050093061014005047091091000000000000045000000000000000000039000000", a: 89, h: 47, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000005021000000008022000000000000000028075032000007069078029000000000039082035000025072037022078026005051076016000000044026000000022074074069009000000000000000000000000034044001000000000000000000006000000000000000000000000000009067073005000000000000000000000000054048059072007000000000040067069035009000005072076006000045093069069035000000000004074064060097022000000000000000000000002060060007000000000000", a: 108, h: 134, s: 38})
	TotemEvt.Push({n: "Shiny", g: "000000000000000011001000000000000000000000000000000036021000000000000000000000000000000056052000000000000000000000000000018050057018000000000000027036041046069020029070046038035020021076065023024000000025035076072015000017072024000000000000036070016000000000014082020000000020073005000000000000011085005026016005074000000000000000024082056083082051084003000000000000043088062008011066088026000000000000038022000000000000027035000000", a: 103, h: 47, s: 39})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000011040000000011032001000000000000021076036000009070083028000000000023078041000041072023010067035006048074020000000024000000000008076089053000000000000000000000000000018042001000000000000000000003000000000000000000000000000026070078011000000000000000000000000054014033090019000000000050107110073000000000053073010000046100057055036000000000000069065040098019000000000000000000000004061079011000000000000", a: 107, h: 134, s: 38})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000017000000000000000000000000000000023050000000000000000000000000000001059071012000000000000000000000000021061042038000000000000024032034038063017001063047034032024014081075013008000000008017065084025000013076024000000000000011075033000000000016082022000000003084031000000000000001083017001016000082017000000000000012092054080079055081038000000000000031096063000000042096062000000000000036027000000000000012041000000", a: 100, h: 46, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000035000000015039004000000000000034069023000003087091051000000000046095032000006072027002063039000050066015000000013017000000000085092074000000000000000000000000000019046003000000000000000000002000000000000000000000000000002060081021000000000000000000000000026040041094026000000000053109112056000000000044084013000044086056056028000000000000044081064098000000000000000000000000000062072013000000000000", a: 111, h: 135, s: 40})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000017000000000000000000000000000000020036000000000000000000000000000000039069000000000000000000000000000000059055025000000000000000000000021070040026079032000000000042084080039041012000042043077083041000021077050000000000000026086030000000000000080021000000000091005000000000000000078000006018000075000000000000000000092009087092035068021000000000000014096080034022065096087000000000000056026000000000000016049000000", a: 100, h: 48, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000023000000004023000000000000000012061054000007066080031000000000026076052005024075048020079034001043085037000000042028000000021078069072015000000000000000000000000022060004000000000000000000009000000000000000000000000000011063080019000000000000000000000000052049047073009000000000026062065049008000000059077009000029091065065048000000000004067072040087027000000000000000000000002049074016000000000000", a: 105, h: 134, s: 39})
	TotemEvt.Push({n: "Shiny", g: "000000000000000011000000000000000000000000000000000032017000000000000000000000000000000055046000000000000000000000000000016051059018000000000000027038039050070021032074046039040021024078064024026000000027034076075016000017069022000000000000035073016000000000015083019000000023074005000000000000009085005027017005075000000000000000023081051082082052083003000000000000044084061007011061083027000000000000038021000000000000028037000000", a: 103, h: 48, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000011040000000013036003000000000000023078041000008074087030000000000020079039000039078027009069036005049079022000000025002000000006079093052000000000000000000000000000020045000000000000000000000004000000000000000000000000000028072082011000000000000000000000000052018030089021000000000041097104068000000000052077010000040094055052034000000000000061065040094018000000000000000000000004058076012000000000000", a: 107, h: 133, s: 38})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000017000000000000000000000000000000012040000000000000000000000000000000037066016000000000000000000000000000058040058000000000000025032033042055038001069051031031031016083073011010000000007013052083054000011073019000000000000005069064004000000015083033000000000062046000000000000000083025001014000057027000000000000010090044072077063066053000000000000031091073011000022083091000000000000035027000000000000007049010000", a: 97, h: 48, s: 41})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000032000000014041007000000000000032074026000002089092055000000000039101029000008075030003063039000053068019000000025023000000000089093072000000000000000000000000000022046000000000000000000000007000000000000000000000000000000062083024000000000000000000000000027048037101028000000000042104104052000000000041085013000037080050052026000000000000034081060095000000000000000000000000000057074014000000000000", a: 111, h: 134, s: 40})
	TotemEvt.Push({n: "Shiny", g: "000000000000000000027000000000000000000000000000000028061000000000000000000000000000000071061022000000000000000000000000029045031048000000000000000000000042068000000064046008000000076079054039033000000020040050074065000035062026000000000000006059042005000000033081005000000000088042000000000000025086000014027000055043000000000000041082036085084059037047000000000000049083056013004043083079000000000000045003000000000000000036000000", a: 89, h: 48, s: 41})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000006026000000009026000000000000000026076031000015072078028000000000045080032000030078039026083022004055076015000000049023000000025075074068008000000000000000000000000035042000000000000000000001007000000000000000000000000000011070071005000000000000000000000000058048056073007000000000037065066033010000005070075004000044087066066033000000000004071059058090019000000000000000000000003058059008000000000000", a: 108, h: 142, s: 45})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000017000000000005000000000000000000050059000010061081020000000000021072053005036086040019082012000038090032000000068032000000041078052082021000000000003000000000000038060010000000000000000000005000000000000000000000000000012074075000000000000000000000000000065040052075012000000000033071072048000000000057077004000044100054053036000000000000071063040097016000000000000000000000005061078012000000000000", a: 104, h: 142, s: 45})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000041000000018044003000000000000037069021000011088087050000000000058091027000012075024000068030000058062008000000031013000000000088095067000000000000000000000000000021042000000000000000000000001000000000000000000000000000004067078021000000000000000000000000028039047096022000000000049107110055000000000043082009000045080054055027000000000000044073065098000000000000000000000000000062067014000000000000", a: 111, h: 142, s: 47})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000007025000000008025000000000000000026073030000016068077027000000000043080032000025075037026079020004054073015000000048022000000023072074069010000000000000000000000000036042000000000000000000002009000000000000000000000000000013073069006000000000000000000000000060047059074009000000000040064066032011000006076070005000044090066067033000000000005073062060090022000000000000000000000003061061009000000000000", a: 108, h: 135, s: 38})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000016000000000007000000000000000000048058000011056077019000000000019071054005031082037020078012000036088030000000063031000000038073054081021000000000004000000000000037058010000000000000000000007000000000000000000000000000014076074000000000000000000000000000069038056078013000000000034071073048000000000062075005000045102058055036000000000000073067042098020000000000000000000000005064084012000000000000", a: 104, h: 134, s: 38})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000040000000017041002000000000000037070021000012080082047000000000051091028000009069021001063028000056061009000000029014000000000084092070000000000000000000000000000021038001000000000000000000002000000000000000000000000000009067079019000000000000000000000000036040046097026000000000052108110056000000000047081010000046087054056028000000000000046078067098000000000000000000000000000064074014000000000000", a: 111, h: 135, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000007025000000007024000000000000000026076030000012070075029000000000044080031000027073035024077022005057073014000000046022000000022073072066008000000000000000000000000035042000000000000000000000008000000000000000000000000000012070072006000000000000000000000000060048060077008000000000038065067033011000006076078004000043092066068034000000000004075066060094022000000000000000000000003062061008000000000000", a: 108, h: 137, s: 39})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000018000000000003000000000000000000052057000009058077021000000000021071053005034080035018076015000039088030000000061030000000035075050078020000000000002000000000000038058010000000000000000000007000000000000000000000000000012072076000000000000000000000000000069039055079013000000000034069072048000000000062080007000045103056055036000000000000076071043101019000000000000000000000005066081013000000000000", a: 104, h: 136, s: 39})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000040000000017041004000000000000035070020000010084080050000000000056090023000012067022000061030001056061008000000027015000000000086085065000000000000000000000000000021040001000000000000000000001000000000000000000000000000007066079022000000000000000000000000039039046098023000000000049105108055000000000048086010000046084053054028000000000000048081070102000000000000000000000000000067070017000000000000", a: 111, h: 136, s: 40})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000033000000002027000000000000000012067053000017071086031000000000036083053003032082050024084028000048083032000000050024000000024081064070010000000000000000000000000018044004000000000000000017036000000000000000000000000000033082082035000000000000000000000000049021023083023000000000056087087068000000000033082019000056077030028022000000000000039081061065006000000000000000000000000023045004000000000000", a: 103, h: 148, s: 47})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000021000000000005000000000000000002056062000008057090036000000000024078058007012085059022093036000043095032000000039051000000022084055086022000000000005000000000000028061010000000000000000000013000000000000000000000000000000063090013000000000000000000000000035054041081016000000000033065066044000000000038093014000042096052049032000000000000051075041089017000000000000000000000000045071013000000000000", a: 107, h: 147, s: 48})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000000000000000000000000000000000000035044000000040096006000000000000079091000000049077052078003000016080062014000052086000000051055004092038000000000025008000000000069088035000000000000000000004000000000000000000000000000000047067000000000000000000000000000038067070074012000000000023049049025012000000089074000000013100100099049000000000000064048032081026000000000000000000000000059064015000000000000", a: 105, h: 147, s: 49})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000001034000000003028000000000000000013066054000017073086030000000000036084054003032085049024084029000048082033000000049024000000024081066071010000000000000000000000000018045004000000000000000015036000000000000000000000000000033084082035000000000000000000000000049020021081022000000000055086085065000000000033082019000056076030028021000000000000040081062064005000000000000000000000000023047004000000000000", a: 103, h: 149, s: 46})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000022000000000005000000000000000003055062000007059091036000000000024079059008012087058023093036000044094034000000038051000000024083057086023000000000005000000000000029063010000000000000000000012000000000000000000000000000000061091014000000000000000000000000034053041078016000000000033064064043001000000039092015000043095051048032000000000000052075041088017000000000000000000000000044073013000000000000", a: 107, h: 148, s: 47})
	TotemEvt.Push({n: "Aurora", g: "000000000000000000000000000000000000000000000000000000000000000000035045000000041097007000000000000083090002000050075052077004000016079063015000050085000000050055008092037000000000024009000000001070090035000000000000000000004000000000000000000000000000000045068000000000000000000000000000038068069072012000000000024048048024015000000089073000000014099097097048000000000000065048032080028000000000000000000000000059066015000000000000", a: 105, h: 148, s: 48})
}

TotemMedSmall(vals, n) {
	i := 2
	while (i <= n)
		{
		v := vals[i]
		j := i - 1
		while (j >= 1 and vals[j] > v)
			{
			vals[j + 1] := vals[j]
			j--
			}
		vals[j + 1] := v
		i++
		}
	return vals[(n + 1) // 2]
}

TotemSlotRead(x0, x1, y0, y1, ih, gap, D) {
	global pTotemBits, TotemW, TotemH
	bw := x1 - x0 + 1
	bh := y1 - y0 + 1
	m := Round(bw * 0.12)
	if (m < 2)
		m := 2
	if (bw < 3 * m or bh < 3 * m)
		return {st: "junk", n: 0}
	Lb := []
	Lg := []
	Lr := []
	Rb := []
	Rg := []
	Rr := []
	Tb := []
	Tg := []
	Tr := []
	Bb := []
	Bg := []
	Br := []
	vb := []
	vg := []
	vr := []
	y := 0
	while (y < bh)
		{
		roff := ((y0 + y) * TotemW + x0) * 4
		i := 1
		while (i <= m)
			{
			pv := NumGet(pTotemBits + 0, roff + ((i - 1) * 4), "UInt")
			vb[i] := pv & 0xFF
			vg[i] := (pv >> 8) & 0xFF
			vr[i] := (pv >> 16) & 0xFF
			i++
			}
		Lb[y] := TotemMedSmall(vb, m)
		Lg[y] := TotemMedSmall(vg, m)
		Lr[y] := TotemMedSmall(vr, m)
		i := 1
		while (i <= m)
			{
			pv := NumGet(pTotemBits + 0, roff + ((bw - m + i - 1) * 4), "UInt")
			vb[i] := pv & 0xFF
			vg[i] := (pv >> 8) & 0xFF
			vr[i] := (pv >> 16) & 0xFF
			i++
			}
		Rb[y] := TotemMedSmall(vb, m)
		Rg[y] := TotemMedSmall(vg, m)
		Rr[y] := TotemMedSmall(vr, m)
		y++
		}
	x := 0
	while (x < bw)
		{
		i := 1
		while (i <= m)
			{
			pv := NumGet(pTotemBits + 0, ((y0 + i - 1) * TotemW + x0 + x) * 4, "UInt")
			vb[i] := pv & 0xFF
			vg[i] := (pv >> 8) & 0xFF
			vr[i] := (pv >> 16) & 0xFF
			i++
			}
		Tb[x] := TotemMedSmall(vb, m)
		Tg[x] := TotemMedSmall(vg, m)
		Tr[x] := TotemMedSmall(vr, m)
		i := 1
		while (i <= m)
			{
			pv := NumGet(pTotemBits + 0, ((y0 + bh - m + i - 1) * TotemW + x0 + x) * 4, "UInt")
			vb[i] := pv & 0xFF
			vg[i] := (pv >> 8) & 0xFF
			vr[i] := (pv >> 16) & 0xFF
			i++
			}
		Bb[x] := TotemMedSmall(vb, m)
		Bg[x] := TotemMedSmall(vg, m)
		Br[x] := TotemMedSmall(vr, m)
		x++
		}
	VarSetCapacity(dd, bw * bh * 2, 0)
	cnt := []
	x := 0
	while (x < bw)
		{
		cnt[x] := 0
		x++
		}
	n := 0
	y := 0
	while (y < bh)
		{
		roff := ((y0 + y) * TotemW + x0) * 4
		x := 0
		while (x < bw)
			{
			pv := NumGet(pTotemBits + 0, roff + (x * 4), "UInt")
			qb := pv & 0xFF
			qg := (pv >> 8) & 0xFF
			qr := (pv >> 16) & 0xFF
			hb := Lb[y] + Floor((Rb[y] - Lb[y]) * x / (bw - 1))
			hg := Lg[y] + Floor((Rg[y] - Lg[y]) * x / (bw - 1))
			hr := Lr[y] + Floor((Rr[y] - Lr[y]) * x / (bw - 1))
			ub := Tb[x] + Floor((Bb[x] - Tb[x]) * y / (bh - 1))
			ug := Tg[x] + Floor((Bg[x] - Tg[x]) * y / (bh - 1))
			ur := Tr[x] + Floor((Br[x] - Tr[x]) * y / (bh - 1))
			bgb := (hb + ub) // 2
			bgg := (hg + ug) // 2
			bgr := (hr + ur) // 2
			dv := ((qb > bgb) ? qb - bgb : bgb - qb) + ((qg > bgg) ? qg - bgg : bgg - qg) + ((qr > bgr) ? qr - bgr : bgr - qr)
			NumPut(dv, dd, (y * bw + x) * 2, "UShort")
			if (dv >= D and x >= m and x < bw - m and y >= m and y < bh - m)
				{
				n++
				cnt[x] := cnt[x] + 1
				}
			x++
			}
		y++
		}
	area := (bh - 2 * m) * (bw - 2 * m)
	if (n * 100 < 5 * area)
		return {st: "empty", n: n}
	rs := []
	re := []
	nr := 0
	st := -1
	x := 0
	while (x < bw)
		{
		if (cnt[x] >= 2)
			{
			if (st < 0)
				st := x
			}
		else if (st >= 0)
			{
			nr++
			rs[nr] := st
			re[nr] := x - 1
			st := -1
			}
		x++
		}
	if (st >= 0)
		{
		nr++
		rs[nr] := st
		re[nr] := bw - 1
		}
	if (nr < 1)
		return {st: "empty", n: n}
	ms := []
	me := []
	nm := 0
	ri := 1
	while (ri <= nr)
		{
		if (nm > 0 and (rs[ri] - me[nm] - 1) <= gap)
			me[nm] := re[ri]
		else
			{
			nm++
			ms[nm] := rs[ri]
			me[nm] := re[ri]
			}
		ri++
		}
	bestN := -1
	a := 0
	b := 0
	mi := 1
	while (mi <= nm)
		{
		cs := 0
		x := ms[mi]
		while (x <= me[mi])
			{
			cs := cs + cnt[x]
			x++
			}
		if (cs > bestN)
			{
			bestN := cs
			a := ms[mi]
			b := me[mi]
			}
		mi++
		}
	gS := -1
	gE := -1
	gN := 0
	bS := -1
	bE := -1
	bN := -1
	y := m
	while (y < bh - m)
		{
		rn := 0
		x := a
		while (x <= b)
			{
			if (x >= m and x < bw - m and NumGet(dd, (y * bw + x) * 2, "UShort") >= D)
				rn++
			x++
			}
		if (rn > 0)
			{
			if (gS >= 0 and y - gE - 1 > gap)
				{
				if (gN > bN)
					{
					bS := gS
					bE := gE
					bN := gN
					}
				gS := -1
				}
			if (gS < 0)
				{
				gS := y
				gN := 0
				}
			gE := y
			gN := gN + rn
			}
		y++
		}
	if (gS >= 0 and gN > bN)
		{
		bS := gS
		bE := gE
		bN := gN
		}
	if (bS < 0)
		return {st: "empty", n: n}
	iw := b - a + 1
	ihh := bE - bS + 1
	ni := bN
	if (iw * 100 < 45 * ih or iw * 100 > 170 * ih or ihh * 100 < 55 * ih or ihh * 100 > 135 * ih)
		return {st: "junk", n: n}
	if (ni * 100 < 10 * iw * ihh or ni * 100 > 92 * iw * ihh)
		return {st: "junk", n: n}
	hd := []
	hi := 0
	while (hi <= 765)
		{
		hd[hi] := 0
		hi++
		}
	y := bS
	while (y <= bE)
		{
		x := a
		while (x <= b)
			{
			dv := NumGet(dd, (y * bw + x) * 2, "UShort")
			if (dv > 765)
				dv := 765
			hd[dv] := hd[dv] + 1
			x++
			}
		y++
		}
	tn := iw * ihh
	acc := 0
	pk := 765
	hi := 0
	while (hi <= 765)
		{
		acc := acc + hd[hi]
		if (acc * 100 >= 98 * tn)
			{
			pk := hi
			break
			}
		hi++
		}
	dn := Round(pk * 0.35)
	if (dn < D)
		dn := D
	if (pk - dn < 20)
		return {st: "junk", n: n}
	grid := []
	gsum := 0
	gi := 0
	while (gi < 12)
		{
		gj := 0
		while (gj < 12)
			{
			sy0 := (ihh * gi) // 12
			sy1 := (ihh * (gi + 1)) // 12
			if (sy1 <= sy0)
				sy1 := sy0 + 1
			sx0 := (iw * gj) // 12
			sx1 := (iw * (gj + 1)) // 12
			if (sx1 <= sx0)
				sx1 := sx0 + 1
			ct := 0.0
			cn := 0
			yy := sy0
			while (yy < sy1)
				{
				xx := sx0
				while (xx < sx1)
					{
					dv := NumGet(dd, ((bS + yy) * bw + a + xx) * 2, "UShort")
					if (dv > 765)
						dv := 765
					fv := (dv - dn) / (pk - dn)
					if (fv > 1)
						fv := 1
					if (fv > 0)
						ct := ct + fv
					cn++
					xx++
					}
				yy++
				}
			gv := Floor(ct / cn * 100)
			grid[gi * 12 + gj] := gv
			gsum := gsum + gv
			gj++
			}
		gi++
		}
	if (gsum < 1)
		return {st: "junk", n: n}
	gmean := gsum / 144
	gi := 0
	while (gi < 144)
		{
		grid[gi] := Round(grid[gi] / gmean * 20)
		gi++
		}
	sr := 0
	sg := 0
	sb := 0
	sc := 0
	y := bS
	while (y <= bE)
		{
		roff := ((y0 + y) * TotemW + x0) * 4
		x := a
		while (x <= b)
			{
			dv := NumGet(dd, (y * bw + x) * 2, "UShort")
			if (dv > 765)
				dv := 765
			if (dv >= dn)
				{
				pv := NumGet(pTotemBits + 0, roff + (x * 4), "UInt")
				sb := sb + (pv & 0xFF)
				sg := sg + ((pv >> 8) & 0xFF)
				sr := sr + ((pv >> 16) & 0xFF)
				sc++
				}
			x++
			}
		y++
		}
	if (sc < 4)
		return {st: "junk", n: n}
	ar2 := sr // sc
	ag2 := sg // sc
	ab2 := sb // sc
	mx2 := (ar2 > ag2) ? ar2 : ag2
	if (ab2 > mx2)
		mx2 := ab2
	mn2 := (ar2 < ag2) ? ar2 : ag2
	if (ab2 < mn2)
		mn2 := ab2
	isat := (mx2 > 0) ? ((mx2 - mn2) * 100) // mx2 : 0
	ihue := (isat >= 12) ? TotemHue(ar2, ag2, ab2) : -1
	return {st: "icon", n: n, g: grid, ar: Round(iw * 100 / ihh), hue: ihue, sat: isat, x0: x0 + a, x1: x0 + b, y0: y0 + bS, y1: y0 + bE}
}

TotemEvtBest(grid, ar100, hue, sat, ByRef bD, ByRef nD) {
	global TotemEvt
	per := {}
	for eI, et in TotemEvt
		{
		d := 0
		gi := 0
		while (gi < 144)
			{
			dv := grid[gi] - (SubStr(et.g, gi * 3 + 1, 3) + 0)
			d := d + ((dv < 0) ? 0 - dv : dv)
			gi++
			}
		d := d + Abs(ar100 - et.a) * 8
		if (et.h >= 0 and hue >= 0)
			{
			hd := Abs(et.h - hue)
			if (hd > 180)
				hd := 360 - hd
			d := d + hd * 20 + Abs(sat - et.s) * 15
			}
		else
			d := d + 2000
		if (!per.HasKey(et.n) or d < per[et.n])
			per[et.n] := d
		}
	bN := ""
	bD := 999999
	nD := 999999
	for pn, pd in per
		{
		if (pd < bD)
			{
			nD := bD
			bD := pd
			bN := pn
			}
		else if (pd < nD)
			nD := pd
		}
	return bN
}

TotemStripInit() {
	global hTotemMemDC, hTotemScreenDC, hTotemBM, pTotemBits
	global TotemW, TotemH, TotemX0, TotemY0, WindowWidth, WindowHeight
	nx0 := Round(WindowWidth * 0.836)
	ny0 := Round(WindowHeight * 0.876)
	nw := Round(WindowWidth * 0.162)
	nh := Round(WindowHeight * 0.048)
	if (nw < 48)
		nw := 48
	if (nh < 20)
		nh := 20
	if (hTotemMemDC and nw = TotemW and nh = TotemH)
		{
		TotemX0 := nx0
		TotemY0 := ny0
		return true
		}
	if (hTotemMemDC)
		{
		DllCall("DeleteObject", "Ptr", hTotemBM)
		DllCall("DeleteDC", "Ptr", hTotemMemDC)
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hTotemScreenDC)
		hTotemMemDC := 0
		}
	TotemX0 := nx0
	TotemY0 := ny0
	TotemW := nw
	TotemH := nh
	hTotemScreenDC := DllCall("GetDC", "Ptr", 0, "Ptr")
	hTotemMemDC := DllCall("CreateCompatibleDC", "Ptr", hTotemScreenDC, "Ptr")
	VarSetCapacity(TotemBMI, 40, 0)
	NumPut(40, TotemBMI, 0, "UInt")
	NumPut(TotemW, TotemBMI, 4, "Int")
	NumPut(-TotemH, TotemBMI, 8, "Int")
	NumPut(1, TotemBMI, 12, "UShort")
	NumPut(32, TotemBMI, 14, "UShort")
	NumPut(0, TotemBMI, 16, "UInt")
	hTotemBM := DllCall("CreateDIBSection", "Ptr", hTotemScreenDC, "Ptr", &TotemBMI, "UInt", 0, "Ptr*", pTotemBits, "Ptr", 0, "UInt", 0, "Ptr")
	if (!hTotemBM)
		{
		hTotemMemDC := 0
		return false
		}
	DllCall("SelectObject", "Ptr", hTotemMemDC, "Ptr", hTotemBM)
	return true
}

TotemCaptureStrip() {
	global hTotemMemDC, hTotemScreenDC, TotemW, TotemH, TotemX0, TotemY0, RobloxHwnd
	if (!hTotemMemDC or !RobloxHwnd)
		return false
	RobloxClientRect(RobloxHwnd, twx, twy)
	DllCall("BitBlt", "Ptr", hTotemMemDC, "Int", 0, "Int", 0, "Int", TotemW, "Int", TotemH
		, "Ptr", hTotemScreenDC, "Int", twx + TotemX0, "Int", twy + TotemY0, "UInt", 0x00CC0020)
	return true
}

;====================================================================================================;
;
;====================================================================================================;

KbPixFill(px) {
	r := (px >> 16) & 0xFF
	g := (px >> 8) & 0xFF
	b := px & 0xFF
	return (b >= 215 and r >= 95 and g <= 140 and r > g + 5)
}

KbPixNavy(px) {
	r := (px >> 16) & 0xFF
	g := (px >> 8) & 0xFF
	b := px & 0xFF
	return (Abs(r - 12) <= 14 and Abs(g - 30) <= 14 and Abs(b - 42) <= 16)
}

KbGrab(x, y, w, h, ByRef hdcM, ByRef hbm, ByRef old) {
	hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
	hdcM := DllCall("CreateCompatibleDC", "Ptr", hdcS, "Ptr")
	VarSetCapacity(bi, 40, 0)
	NumPut(40, bi, 0, "UInt")
	NumPut(w, bi, 4, "Int")
	NumPut(-h, bi, 8, "Int")
	NumPut(1, bi, 12, "UShort")
	NumPut(32, bi, 14, "UShort")
	pBits := 0
	hbm := DllCall("CreateDIBSection", "Ptr", hdcM, "Ptr", &bi, "UInt", 0, "Ptr*", pBits, "Ptr", 0, "UInt", 0, "Ptr")
	if (!hbm)
		{
		DllCall("DeleteDC", "Ptr", hdcM)
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
		return 0
		}
	old := DllCall("SelectObject", "Ptr", hdcM, "Ptr", hbm, "Ptr")
	DllCall("BitBlt", "Ptr", hdcM, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcS, "Int", x, "Int", y, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
	return pBits
}

KbGrabEnd(hdcM, hbm, old) {
	DllCall("SelectObject", "Ptr", hdcM, "Ptr", old)
	DllCall("DeleteObject", "Ptr", hbm)
	DllCall("DeleteDC", "Ptr", hdcM)
}

; finds the Keeperbound power bar (purple fill + dark navy track) on its own - no setup
KbAutoFind() {
	global RobloxHwnd, KbBarY, KbBarL, KbBarR, KbBarWW, KbBarWH, KbBarTop, KbBarBot
	KbBarY := -1
	if (!RobloxHwnd)
		return false
	RobloxClientRect(RobloxHwnd, wx, wy, ww, wh)
	if (ww < 200 or wh < 200)
		return false
	y0 := Round(wh * 0.45)
	h := wh - y0
	w := ww
	pBits := KbGrab(wx, wy + y0, w, h, hdcM, hbm, old)
	if (!pBits)
		return false
	; the bar is about 960 px wide at every window size, so the limits are in pixels - a gap measured as a share
	; of the window let the bar run on into dark water past its end on a 4K screen (99.8% read as 70%)
	gap := 30
	minRun := Round(w * 0.18)
	if (minRun > 450)
		minRun := 450
	rows := []
	Loop % h
		{
		y := A_Index - 1
		base := pBits + y * w * 4
		hits := 0
		hx := -1
		Loop 9
			{
			x := Round(w * (0.30 + 0.05 * (A_Index - 1)))
			px := NumGet(base + 0, x * 4, "UInt")
			if (KbPixFill(px) or KbPixNavy(px))
				{
				hits++
				hx := x
				}
			}
		if (hits < 2)
			continue
		L := hx
		R := hx
		good := 1
		fills := KbPixFill(NumGet(base + 0, hx * 4, "UInt")) ? 1 : 0
		miss := 0
		x := hx - 1
		while (x >= 0)
			{
			px := NumGet(base + 0, x * 4, "UInt")
			f := KbPixFill(px)
			if (f or KbPixNavy(px))
				{
				L := x
				good++
				fills += f
				miss := 0
				}
			else if (++miss > gap)
				break
			x--
			}
		miss := 0
		x := hx + 1
		while (x < w)
			{
			px := NumGet(base + 0, x * 4, "UInt")
			f := KbPixFill(px)
			if (f or KbPixNavy(px))
				{
				R := x
				good++
				fills += f
				miss := 0
				}
			else if (++miss > gap)
				break
			x++
			}
		; 45%: a fish or effect drifting over part of the bar must not hide it
		if (R - L + 1 >= minRun and good >= 0.45 * (R - L + 1))
			rows.Push([y, L, R, fills])
		}
	KbGrabEnd(hdcM, hbm, old)
	if (rows.Length() < 3)
		return false
	; candidates are runs of 3+ rows in a row. Dark water looks just like the empty (navy) track, so the bar is
	; the run with the most purple fill - not the tallest one. No purple anywhere (empty bar): the lowest run.
	bs := 0
	bn := 0
	bScore := -1
	cs := 1
	n := rows.Length()
	Loop % n
		{
		i := A_Index
		if (i < n and rows[i + 1][1] = rows[i][1] + 1)
			continue
		len := i - cs + 1
		if (len >= 3)
			{
			sc := 0
			Loop % len
				sc += rows[cs + A_Index - 1][4]
			if (sc > bScore or (sc = 0 and bScore = 0))
				{
				bScore := sc
				bs := cs
				bn := len
				}
			}
		cs := i + 1
		}
	if (bn < 3)
		return false
	ls := []
	rs := []
	Loop % bn
		{
		ls.Push(rows[bs + A_Index - 1][2])
		rs.Push(rows[bs + A_Index - 1][3])
		}
	KbBarY := y0 + rows[bs + (bn // 2)][1]
	KbBarTop := y0 + rows[bs][1]
	KbBarBot := y0 + rows[bs + bn - 1][1]
	KbBarL := MedianOf(ls)
	KbBarR := MedianOf(rs)
	KbBarWW := ww
	KbBarWH := wh
	return true
}

; reads how full the power bar is, 0-100. false if the bar is not on screen
; The "45.0% Power" text sits on top of the middle of the bar with a thick navy outline (the same navy as
; the empty track), so the fill edge cannot just be "where the navy starts". Instead every pixel is evidence:
; purple = filled here, navy that is NOT part of a letter outline = empty here. The reading is the split point
; that best separates the two (a step fit), which also sees through the gaps between the letters.
KbAutoRead(ByRef pct, ByRef lo := "", ByRef hi := "") {
	global RobloxHwnd, KbBarY, KbBarL, KbBarR, KbBarWW, KbBarWH, KbBarTop, KbBarBot
	pct := -1
	lo := -1
	hi := -1
	if (!RobloxHwnd)
		return false
	Loop 2
		{
		RobloxClientRect(RobloxHwnd, wx, wy, ww, wh)
		fresh := false
		if (KbBarY = "" or KbBarY < 0 or KbBarTop = "" or ww != KbBarWW or wh != KbBarWH)
			{
			if (!KbAutoFind())
				return false
			fresh := true
			}
		w := Round(KbBarR - KbBarL + 1)
		nr := KbBarBot - KbBarTop + 1
		if (w < 20 or nr < 3)
			{
			KbBarY := -1
			continue
			}
		pBits := KbGrab(wx + Round(KbBarL), wy + KbBarTop, w, nr, hdcM, hbm, old)
		if (!pBits)
			return false
		; 1 = fill, 2 = navy, 3 = letter
		VarSetCapacity(cls, w * nr, 0)
		rowF := []
		rowN := []
		Loop % nr
			{
			r := A_Index - 1
			base := pBits + r * w * 4
			ob := r * w
			fc := 0
			nc := 0
			x := 0
			while (x < w)
				{
				px := NumGet(base + 0, x * 4, "UInt")
				cr := (px >> 16) & 0xFF
				cg := (px >> 8) & 0xFF
				cb := px & 0xFF
				if (cb >= 215 and cr >= 95 and cg <= 140 and cr > cg + 5)
					{
					NumPut(1, cls, ob + x, "UChar")
					fc++
					}
				else if (cr <= 26 and cg >= 16 and cg <= 44 and cb >= 26 and cb <= 58)
					{
					NumPut(2, cls, ob + x, "UChar")
					nc++
					}
				else if (cr >= 150 and cg >= 145 and cb >= 190)
					NumPut(3, cls, ob + x, "UChar")
				x++
				}
			rowF.Push(fc)
			rowN.Push(nc)
			}
		KbGrabEnd(hdcM, hbm, old)
		; drop the purple border rows at the top and bottom of the bar
		maxN := 0
		for i, v in rowN
			maxN := (v > maxN) ? v : maxN
		r0 := 2
		r1 := nr - 1
		if (nr <= 4)
			{
			r0 := 1
			r1 := nr
			}
		while (r0 < r1 and maxN > 0.05 * w and rowN[r0] < 0.02 * w and rowF[r0] > 0.9 * w)
			r0++
		while (r1 > r0 and maxN > 0.05 * w and rowN[r1] < 0.02 * w and rowF[r1] > 0.9 * w)
			r1--
		ih := r1 - r0 + 1
		d := Round(ih * 0.25)
		if (d < 2)
			d := 2
		; navy within d px of a letter is outline, not empty track
		VarSetCapacity(nh, w * nr, 0)
		r := r0
		while (r <= r1)
			{
			ob := (r - 1) * w
			last := -100000
			x := 0
			while (x < w)
				{
				if (NumGet(cls, ob + x, "UChar") = 3)
					last := x
				if (x - last <= d)
					NumPut(1, nh, ob + x, "UChar")
				x++
				}
			last := 100000
			x := w - 1
			while (x >= 0)
				{
				if (NumGet(cls, ob + x, "UChar") = 3)
					last := x
				if (last - x <= d)
					NumPut(1, nh, ob + x, "UChar")
				x--
				}
			r++
			}
		VarSetCapacity(fe, w * 8, 0)
		totF := 0
		totE := 0
		x := 0
		while (x < w)
			{
			f := 0
			e := 0
			r := r0
			while (r <= r1)
				{
				c := NumGet(cls, (r - 1) * w + x, "UChar")
				if (c = 1)
					f++
				else if (c = 2)
					{
					near := false
					rr := (r - d < r0) ? r0 : r - d
					re := (r + d > r1) ? r1 : r + d
					while (rr <= re)
						{
						if (NumGet(nh, (rr - 1) * w + x, "UChar"))
							{
							near := true
							break
							}
						rr++
						}
					if (!near)
						e++
					}
				r++
				}
			NumPut(f, fe, x * 8, "UInt")
			NumPut(e, fe, x * 8 + 4, "UInt")
			totF += f
			totE += e
			x++
			}
		if (totF + totE < 0.3 * w * ih)
			{
			; not the bar any more (menu open, rod swapped, window moved) - look for it again
			KbBarY := -1
			continue
			}
		if (totF = 0 and !fresh)
			{
			; no purple at all where the bar was seen before - it may have locked onto dark water; look again
			KbBarY := -1
			continue
			}
		costL := 0
		costR := totF
		best := 0x7FFFFFFF
		bx0 := 0
		bx1 := 0
		x := 0
		while (x <= w)
			{
			cost := costL + costR
			if (cost < best)
				{
				best := cost
				bx0 := x
				bx1 := x
				}
			else if (cost = best)
				bx1 := x
			if (x < w)
				{
				costL += NumGet(fe, x * 8 + 4, "UInt")
				costR -= NumGet(fe, x * 8, "UInt")
				}
			x++
			}
		lo := bx0 * 100.0 / w
		hi := bx1 * 100.0 / w
		pct := (lo + hi) / 2
		return true
		}
	return false
}

; a few frames, median - steadier than one frame
KbAutoReadStable(ByRef pct, n := 3) {
	vals := []
	Loop % n
		{
		if (KbAutoRead(v))
			vals.Push(v)
		if (A_Index < n)
			Sleep, 40
		}
	if (vals.Length() < (n + 1) // 2)
		return false
	pct := MedianOf(vals)
	return true
}

; is the power bar showing where it was last found? 1 = yes (the rod is in hand), 0 = no purple there,
; -1 = not known (never found yet, or the window changed) - one row of pixels, so it is cheap to poll
KbBarShown() {
	global RobloxHwnd, KbBarY, KbBarL, KbBarR, KbBarWW, KbBarWH, KbBarTop, KbBarBot
	if (!RobloxHwnd or KbBarY = "" or KbBarY < 0 or KbBarTop = "")
		return -1
	RobloxClientRect(RobloxHwnd, wx, wy, ww, wh)
	if (ww != KbBarWW or wh != KbBarWH)
		return -1
	w := Round(KbBarR - KbBarL + 1)
	if (w < 20)
		return -1
	pBits := KbGrab(wx + Round(KbBarL), wy + KbBarTop + (KbBarBot - KbBarTop) // 2, w, 1, hdcM, hbm, old)
	if (!pBits)
		return -1
	f := 0
	x := 0
	while (x < w)
		{
		if (KbPixFill(NumGet(pBits + 0, x * 4, "UInt")))
			f++
		x += 2
		}
	KbGrabEnd(hdcM, hbm, old)
	return (f * 2 >= 0.3 * w) ? 1 : 0
}

; is any minigame on screen? (bar, fish line, the minigame frame, Tranquility notes, Stellarwave signs)
; the full check - only used when a recharge is actually about to start
MgOnScreenChk:
gosub, CaptureFishBar
MgOnScreen := (BarPresent() or FishLineVisible())
; after a few postponements in a row only trust the two strongest signals, so a look-alike cannot block recharging
if (!MgOnScreen and KbPostponeN < 3)
	{
	MgOnScreen := MinigameVisible(6)
	if (!MgOnScreen and SpecialRod = "Tranquility")
		MgOnScreen := ManiaVisible()
	if (!MgOnScreen and SpecialRod = "Stellarwave Melody")
		MgOnScreen := (SwPreset = "Ominous Ouija") ? OjSeen() : (SwFrameTop() >= 0)
	}
return

; reads the power bar while the bobber is out (casting). KbPreState: 0 = no reading or it looked low (the
; restart after the catch reads it the old way and decides), 1 = read and fine - no read needed after the catch
KbPreRead:
KbPreOld := KbOcrCatches
KbOcrCatches := 0
KbPreState := 0
KbAutoAt := KeeperAutoPct
if KbAutoAt is not number
	KbAutoAt := 15
KbPreOk := false
Loop 2
	{
	if (KbAutoRead(KbPct))
		{
		KbPreOk := true
		break
		}
	if (A_Index < 2)
		Sleep, 60
	}
if (!KbPreOk)
	{
	; not on screen right now - the restart reads it instead; after 3 misses in a row stop trying here for a while
	KbOcrCatches := KbPreOld
	KbPreFailN := KbPreFailN + 1
	if (KbPreFailN >= 3)
		{
		KbPreFailN := 0
		KbPreSkip := 10
		}
	return
	}
KbPreFailN := 0
if (KbPct < KbAutoAt + 4)
	{
	; the hotbar can be dimmed while the bobber flies, which reads far too low (0% on a full bar) - a low
	; reading here never starts a recharge, the bar is read again after the catch when the UI is steady
	KbOcrCatches := KbPreOld
	KbOcrLast := "power bar " . Round(KbPct, 1) . "% while casting - checking again after the catch"
	return
	}
KbMissN := 0
KbPreState := 1
KbGoodPct := KbPct
KbSuspect := false
KbOcrLast := "power bar " . Round(KbPct, 1) . "%"
return

; before reading the power bar (every catch): one cheap frame, goes on at once when the bar is gone
KbWaitUiClear:
KbUiClear := false
KbWcT := A_TickCount
Loop
	{
	gosub, CaptureFishBar
	if (SpecialRod = "Tranquility")
		KbWcVis := ManiaVisible()
	else
		KbWcVis := (BarPresent() or FishLineVisible())
	if (!KbWcVis and !MgInPlay)
		{
		KbUiClear := true
		break
		}
	if (A_TickCount - KbWcT >= 600)
		break
	Sleep, 20
	}
return

; right before a recharge: full check, 2 clear frames in a row, at most 1 s - otherwise it is postponed
KbGuardClear:
KbUiClear := false
KbWcT := A_TickCount
KbWcN := 0
Loop
	{
	gosub, MgOnScreenChk
	KbWcN := (MgOnScreen or MgInPlay) ? 0 : KbWcN + 1
	if (KbWcN >= 2)
		{
		KbUiClear := true
		break
		}
	if (A_TickCount - KbWcT >= 1000)
		break
	Sleep, 25
	}
return

KbLineNeed(tot) {
	return 3
}

KbLineCheck(ByRef miss, ByRef tot) {
	global RobloxHwnd, KeeperLineX, KeeperLineY1, KeeperLineY2, KeeperLineColor, KeeperLineTol
	miss := 0
	tot := 0
	col := KeeperLineColor
	if col is not number
		return -1
	if (!RobloxHwnd or col < 0)
		return -1
	y1 := Round(KeeperLineY1)
	y2 := Round(KeeperLineY2)
	if (y2 < y1)
		{
		t := y1
		y1 := y2
		y2 := t
		}
	w := y2 - y1 + 1
	if (w < 3)
		return -1
	tol := KeeperLineTol
	if tol is not number
		tol := 40
	cr := (col >> 16) & 0xFF
	cg := (col >> 8) & 0xFF
	cb := col & 0xFF
	RobloxClientRect(RobloxHwnd, wx, wy)
	hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
	hdcM := DllCall("CreateCompatibleDC", "Ptr", hdcS, "Ptr")
	VarSetCapacity(bi, 40, 0)
	NumPut(40, bi, 0, "UInt")
	NumPut(1, bi, 4, "Int")
	NumPut(-w, bi, 8, "Int")
	NumPut(1, bi, 12, "UShort")
	NumPut(32, bi, 14, "UShort")
	hbm := DllCall("CreateDIBSection", "Ptr", hdcM, "Ptr", &bi, "UInt", 0, "Ptr*", pBits, "Ptr", 0, "UInt", 0, "Ptr")
	if (!hbm)
		{
		DllCall("DeleteDC", "Ptr", hdcM)
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
		return -1
		}
	old := DllCall("SelectObject", "Ptr", hdcM, "Ptr", hbm, "Ptr")
	DllCall("BitBlt", "Ptr", hdcM, "Int", 0, "Int", 0, "Int", 1, "Int", w, "Ptr", hdcS, "Int", wx + Round(KeeperLineX), "Int", wy + y1, "UInt", 0x00CC0020)
	Loop % w
		{
		px := NumGet(pBits + 0, (A_Index - 1) * 4, "UInt")
		b := px & 0xFF
		g := (px >> 8) & 0xFF
		r := (px >> 16) & 0xFF
		if (Abs(r - cr) > tol or Abs(g - cg) > tol or Abs(b - cb) > tol)
			miss++
		}
	DllCall("SelectObject", "Ptr", hdcM, "Ptr", old)
	DllCall("DeleteObject", "Ptr", hbm)
	DllCall("DeleteDC", "Ptr", hdcM)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
	tot := w
	return (miss >= KbLineNeed(w)) ? 1 : 0
}

KbKeyStep(key, ByRef t0) {
	if (!KeyHeld(key))
		{
		t0 := 0
		return false
		}
	if (!t0)
		{
		t0 := A_TickCount
		return true
		}
	return (A_TickCount - t0 >= 300)
}

KbIsEdge(vb, vg, vr, kind) {
	if (kind = "enchant")
		return (vb - vg >= 35 and vr - vg >= 5 and vb > vr and vb >= 90)
	if (kind = "confirm")
		return (vg - vb >= 45 and vg - vr >= 25 and vg >= 110)
	if (kind = "red")
		return (vr - vg >= 60 and vr - vb >= 60 and vr >= 100)
	return false
}

KbRuns(ry, kind, minW, ByRef starts, ByRef ends) {
	global pAqBits, AqW, AqH
	starts := []
	ends := []
	if (ry < 0 or ry >= AqH)
		return 0
	roff := ry * AqW * 4
	runS := -1
	x := 0
	while (x <= AqW)
		{
		on := false
		if (x < AqW)
			{
			pv := NumGet(pAqBits + 0, roff + (x*4), "UInt")
			on := KbIsEdge(pv & 0xFF, (pv >> 8) & 0xFF, (pv >> 16) & 0xFF, kind)
			}
		if (on and runS < 0)
			runS := x
		else if (!on and runS >= 0)
			{
			if (x - runS >= minW)
				{
				starts.Push(runS)
				ends.Push(x)
				}
			runS := -1
			}
		x++
		}
	return starts.MaxIndex() ? starts.MaxIndex() : 0
}

KbBoxes(kind, ByRef bL, ByRef bR, ByRef bT, ByRef bB, yFrom := 0, yTo := -1) {
	global pAqBits, AqW, AqH
	bL := []
	bR := []
	bT := []
	bB := []
	if (!pAqBits or AqW < 120 or AqH < 60)
		return 0
	minW := (kind = "red") ? 24 : 45
	kstep := (kind = "red") ? 3 : 8
	maxW := Round(AqW * 0.45)
	minH := 16
	maxH := 70
	cand := []
	y := (yFrom > 0) ? yFrom : 0
	yEnd := (yTo >= 0 and yTo < AqH) ? yTo + 1 : AqH
	ostep := kstep * 4
	oEnd := AqW * 4
	; the edge colour test is written out per kind and a row stops at 5 hits - calling KbIsEdge for every
	; pixel took over a second per search on a 4K screen
	while (y < yEnd)
		{
		hits := 0
		p := pAqBits + y * AqW * 4
		o := 0
		if (kind = "enchant")
			{
			while (o < oEnd)
				{
				pv := NumGet(p + 0, o, "UInt"), vb := pv & 0xFF, vg := (pv >> 8) & 0xFF, vr := (pv >> 16) & 0xFF
				if (vb - vg >= 35 and vr - vg >= 5 and vb > vr and vb >= 90 and ++hits >= 5)
					break
				o += ostep
				}
			}
		else if (kind = "confirm")
			{
			while (o < oEnd)
				{
				pv := NumGet(p + 0, o, "UInt"), vb := pv & 0xFF, vg := (pv >> 8) & 0xFF, vr := (pv >> 16) & 0xFF
				if (vg - vb >= 45 and vg - vr >= 25 and vg >= 110 and ++hits >= 5)
					break
				o += ostep
				}
			}
		else
			{
			while (o < oEnd)
				{
				pv := NumGet(p + 0, o, "UInt"), vb := pv & 0xFF, vg := (pv >> 8) & 0xFF, vr := (pv >> 16) & 0xFF
				if (vr - vg >= 60 and vr - vb >= 60 and vr >= 100 and ++hits >= 5)
					break
				o += ostep
				}
			}
		if (hits >= 5)
			cand.Push(y)
		y++
		}
	if (!cand.MaxIndex())
		return 0
	lines := []
	i := 1
	prev := -99
	while (i <= cand.MaxIndex())
		{
		if (cand[i] - prev > 2)
			lines.Push(cand[i])
		prev := cand[i]
		i++
		}
	a := 1
	while (a <= lines.MaxIndex())
		{
		ya := lines[a]
		KbRuns(ya, kind, minW, sa, ea)
		b := a + 1
		while (b <= lines.MaxIndex())
			{
			yb := lines[b]
			gap := yb - ya
			if (gap < minH)
				{
				b++
				continue
				}
			if (gap > maxH)
				break
			KbRuns(yb, kind, minW, sb, eb)
			ia := 1
			while (ia <= sa.MaxIndex())
				{
				if (ea[ia] - sa[ia] > maxW)
					{
					ia++
					continue
					}
				ib := 1
				while (ib <= sb.MaxIndex())
					{
					if (Abs(sa[ia] - sb[ib]) <= 8 and Abs(ea[ia] - eb[ib]) <= 8)
						{
						bL.Push(sa[ia])
						bR.Push(ea[ia])
						bT.Push(ya)
						bB.Push(yb)
						}
					ib++
					}
				ia++
				}
			b++
			}
		a++
		}
	return bL.MaxIndex() ? bL.MaxIndex() : 0
}

; nearX/nearY: only a button at that spot (within 15 px) counts - other things on screen can look like one
KbFind(kind, ByRef fx, ByRef fy, want := "", nearX := -1, nearY := -1) {
	global AqX0, AqY0
	fx := -1
	fy := -1
	if (!AqGrab())
		return false
	if (!KbBoxes(kind, gL, gR, gT, gB))
		return false
	; the red button sits on the same rows (top and bottom within 5 px) - only search those rows
	yA := gT[1]
	yB := gB[1]
	for i, v in gT
		yA := (v < yA) ? v : yA
	for i, v in gB
		yB := (v > yB) ? v : yB
	if (!KbBoxes("red", rL, rR, rT, rB, yA - 8, yB + 8))
		return false
	i := 1
	while (i <= gL.MaxIndex())
		{
		j := 1
		while (j <= rL.MaxIndex())
			{
			if (Abs(gT[i] - rT[j]) <= 5 and Abs(gB[i] - rB[j]) <= 5)
				{
				ok := (kind = "enchant") ? (rL[j] > gR[i]) : (rR[j] < gL[i])
				if (ok and nearX >= 0 and (Abs(AqX0 + ((gL[i] + gR[i]) // 2) - nearX) > 15 or Abs(AqY0 + ((gT[i] + gB[i]) // 2) - nearY) > 15))
					ok := false
				if (ok)
					{
					if (want = "red")
						{
						fx := AqX0 + ((rL[j] + rR[j]) // 2)
						fy := AqY0 + ((rT[j] + rB[j]) // 2)
						}
					else
						{
						fx := AqX0 + ((gL[i] + gR[i]) // 2)
						fy := AqY0 + ((gT[i] + gB[i]) // 2)
						}
					return true
					}
				}
			j++
			}
		i++
		}
	return false
}

; 1 = closed, 0 = the key was not pressed, 2 = the key was pressed but the close was not seen
KbFastClose(x, y, col) {
	global KeeperInvKey
	; the confirm box can still be fading out over the button - give the inventory a moment to show again
	; instead of falling back to the slow way (a full screen search per check)
	t0 := A_TickCount
	while (!KbPixNear(x, y, col))
		{
		if (A_TickCount - t0 >= TA("kbfastwait", 400))
			return 0
		Sleep, 10
		}
	SetKeyDelay, 25, 40
	Send, %KeeperInvKey%
	SetKeyDelay, -1, -1
	t0 := A_TickCount
	gone := 0
	while (A_TickCount - t0 < 1200)
		{
		if (!KbPixNear(x, y, col))
			{
			gone++
			if (gone >= 2)
				return 1
			}
		else
			gone := 0
		Sleep, 10
		}
	return 2
}

; the colour at x,y once two reads a moment apart agree (the inventory is still animating otherwise), -1 if not
KbSteadyCol(x, y) {
	PixelGetColor, c1, %x%, %y%, RGB
	if (ErrorLevel)
		return -1
	Loop 4
		{
		Sleep, 40
		PixelGetColor, c2, %x%, %y%, RGB
		if (ErrorLevel)
			return -1
		if (Abs(((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF)) + Abs(((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF)) + Abs((c1 & 0xFF) - (c2 & 0xFF)) <= 12)
			return c2
		c1 := c2
		}
	return -1
}

KbPixNear(x, y, col) {
	PixelGetColor, c, %x%, %y%, RGB
	if (ErrorLevel)
		return false
	d := Abs(((c >> 16) & 0xFF) - ((col >> 16) & 0xFF)) + Abs(((c >> 8) & 0xFF) - ((col >> 8) & 0xFF)) + Abs((c & 0xFF) - (col & 0xFF))
	return (d <= 40)
}

KbWaitFor(kind, ByRef fx, ByRef fy, ms) {
	started := A_TickCount
	Loop
		{
		if (KbFind(kind, fx, fy))
			return true
		if (A_TickCount - started >= ms)
			return false
		Sleep, % Tm(TA("kbpoll", 40))
		}
}

KbKey(k) {
	if (k = "")
		return false
	SetKeyDelay, 25, 40
	Send, %k%
	SetKeyDelay, -1, -1
	Sleep, % Tm(TA("kbkey", 20))
	return true
}

KbSpot(kind, ByRef fx, ByRef fy) {
	global KeeperEnchantX, KeeperEnchantY, KeeperConfirmX, KeeperConfirmY
	if (kind = "enchant")
		{
		if (Round(KeeperEnchantX) > 0 and Round(KeeperEnchantY) > 0)
			{
			fx := Round(KeeperEnchantX)
			fy := Round(KeeperEnchantY)
			return true
			}
		}
	else if (kind = "confirm")
		{
		if (Round(KeeperConfirmX) > 0 and Round(KeeperConfirmY) > 0)
			{
			fx := Round(KeeperConfirmX)
			fy := Round(KeeperConfirmY)
			return true
			}
		}
	return false
}

KbAt(kind, ByRef fx, ByRef fy) {
	if (KbSpot(kind, fx, fy))
		return true
	return KbFind(kind, fx, fy)
}

KbGone(kind, ms, nearX := -1, nearY := -1) {
	started := A_TickCount
	miss := 0
	Loop
		{
		if (!KbFind(kind, gx, gy, "", nearX, nearY))
			{
			miss++
			if (miss >= 2)
				return true
			}
		else
			miss := 0
		if (A_TickCount - started >= ms)
			return false
		Sleep, % Tm(TA("kbgonepoll", 35))
		}
}

KbRodOn() {
	global pAqBits, AqW, AqH, AqY0, WindowHeight
	if (!AqGrab())
		return false
	y0 := Round(WindowHeight * 0.923) - AqY0
	y1 := Round(WindowHeight * 0.942) - AqY0
	if (y0 < 0)
		y0 := 0
	if (y1 >= AqH)
		y1 := AqH - 1
	hits := 0
	y := y0
	while (y <= y1)
		{
		roff := y * AqW * 4
		x := 0
		while (x < AqW)
			{
			pv := NumGet(pAqBits + 0, roff + (x*4), "UInt")
			vb := pv & 0xFF
			vg := (pv >> 8) & 0xFF
			vr := (pv >> 16) & 0xFF
			if (vb > 200 and vr > 130 and vb - vg > 90 and vr - vg > 30)
				hits++
			x += 2
			}
		y++
		}
	return (hits >= 40)
}

KbTap(x, y) {
	MouseMove, %x%, %y%
	Sleep, % Tm(TA("kbtap1", 50))
	Click, Down
	Sleep, % Tm(TA("kbtap2", 35))
	Click, Up
	Sleep, % Tm(TA("kbtap3", 30))
	return
}

KbTapSaved(x, y) {
	global RobloxHwnd
	VarSetCapacity(KbSpt, 8, 0)
	NumPut(x, KbSpt, 0, "Int")
	NumPut(y, KbSpt, 4, "Int")
	if (RobloxHwnd)
		DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &KbSpt)
	KbSx := NumGet(KbSpt, 0, "Int")
	KbSy := NumGet(KbSpt, 4, "Int")
	CoordMode, Mouse, Screen
	MouseMove, %KbSx%, %KbSy%
	Sleep, % Tm(TA("kbtap1", 50))
	Click, Down
	Sleep, % Tm(TA("kbtap2", 35))
	Click, Up
	Sleep, % Tm(TA("kbtap3", 30))
	CoordMode, Mouse, Client
	return
}

;====================================================================================================;
;
;====================================================================================================;

AqRegion() {
	global hAqMemDC, hAqScreenDC, hAqBM, pAqBits, AqW, AqH, AqX0, AqY0
	global WindowWidth, WindowHeight
	nx0 := Round(WindowWidth * 0.04)
	ny0 := Round(WindowHeight * 0.33)
	nw := Round(WindowWidth * 0.92)
	nh := Round(WindowHeight * 0.65)
	if (nw < 120 or nh < 60)
		return false
	if (hAqMemDC and nw = AqW and nh = AqH and nx0 = AqX0 and ny0 = AqY0)
		return true
	if (hAqMemDC)
		{
		DllCall("DeleteObject", "Ptr", hAqBM)
		DllCall("DeleteDC", "Ptr", hAqMemDC)
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hAqScreenDC)
		hAqMemDC := 0
		}
	AqX0 := nx0
	AqY0 := ny0
	AqW := nw
	AqH := nh
	hAqScreenDC := DllCall("GetDC", "Ptr", 0, "Ptr")
	hAqMemDC := DllCall("CreateCompatibleDC", "Ptr", hAqScreenDC, "Ptr")
	VarSetCapacity(AqBMI, 40, 0)
	NumPut(40, AqBMI, 0, "UInt")
	NumPut(AqW, AqBMI, 4, "Int")
	NumPut(-AqH, AqBMI, 8, "Int")
	NumPut(1, AqBMI, 12, "UShort")
	NumPut(32, AqBMI, 14, "UShort")
	NumPut(0, AqBMI, 16, "UInt")
	hAqBM := DllCall("CreateDIBSection", "Ptr", hAqScreenDC, "Ptr", &AqBMI, "UInt", 0, "Ptr*", pAqBits, "Ptr", 0, "UInt", 0, "Ptr")
	if (!hAqBM)
		{
		hAqMemDC := 0
		return false
		}
	DllCall("SelectObject", "Ptr", hAqMemDC, "Ptr", hAqBM)
	return true
}

AqGrab() {
	global hAqMemDC, hAqScreenDC, AqW, AqH, AqX0, AqY0, RobloxHwnd
	if (!AqRegion() or !RobloxHwnd)
		return false
	RobloxClientRect(RobloxHwnd, awx, awy)
	DllCall("BitBlt", "Ptr", hAqMemDC, "Int", 0, "Int", 0, "Int", AqW, "Int", AqH
		, "Ptr", hAqScreenDC, "Int", awx + AqX0, "Int", awy + AqY0, "UInt", 0x00CC0020)
	return true
}

AqEdge(ry, x) {
	global pAqBits, AqW, AqH
	if (ry < 0 or ry >= AqH or x < 0 or x >= AqW)
		return false
	pv := NumGet(pAqBits + 0, (ry*AqW*4) + (x*4), "UInt")
	vb := pv & 0xFF
	vg := (pv >> 8) & 0xFF
	return (vg >= 240 and vb >= 100 and vb <= 160)
}

AqRowRuns(ry, minW, ByRef starts, ByRef ends) {
	global AqW
	starts := []
	ends := []
	runS := -1
	x := 0
	while (x <= AqW)
		{
		on := (x < AqW) ? AqEdge(ry, x) : false
		if (on and runS < 0)
			runS := x
		else if (!on and runS >= 0)
			{
			if (x - runS >= minW)
				{
				starts.Push(runS)
				ends.Push(x)
				}
			runS := -1
			}
		x++
		}
	return starts.MaxIndex() ? starts.MaxIndex() : 0
}

AqFindAll() {
	global pAqBits, AqW, AqH, AqX0, AqY0
	global AqBtnN, AqBtnCX, AqBtnCY, AqBtnKind, AqBtnW, AqBtnH
	AqBtnN := 0
	AqBtnCX := []
	AqBtnCY := []
	AqBtnKind := []
	AqBtnW := 0
	AqBtnH := 0
	if (!pAqBits or AqW < 120 or AqH < 60)
		return 0

	minW := 55
	maxW := Round(AqW * 0.45)
	minH := 16
	maxH := 96

	cand := []
	y := 0
	while (y < AqH)
		{
		hits := 0
		roff := y * AqW * 4
		x := 0
		while (x < AqW)
			{
			pv := NumGet(pAqBits + 0, roff + (x*4), "UInt")
			vb := pv & 0xFF
			if (vb >= 100 and vb <= 160 and ((pv >> 8) & 0xFF) >= 240)
				hits++
			x += 8
			}
		if (hits >= 6)
			cand.Push(y)
		y++
		}
	if (!cand.MaxIndex())
		return 0

	lines := []
	i := 1
	prev := -99
	while (i <= cand.MaxIndex())
		{
		if (cand[i] - prev > 2)
			lines.Push(cand[i])
		prev := cand[i]
		i++
		}

	used := {}
	a := 1
	while (a <= lines.MaxIndex())
		{
		ya := lines[a]
		AqRowRuns(ya, minW, sa, ea)
		b := a + 1
		while (b <= lines.MaxIndex())
			{
			yb := lines[b]
			gap := yb - ya
			if (gap < minH)
				{
				b++
				continue
				}
			if (gap > maxH)
				break
			AqRowRuns(yb, minW, sb, eb)
			ia := 1
			while (ia <= sa.MaxIndex())
				{
				wA := ea[ia] - sa[ia]
				if (wA > maxW)
					{
					ia++
					continue
					}
				ib := 1
				while (ib <= sb.MaxIndex())
					{
					if (Abs(sa[ia] - sb[ib]) <= 6 and Abs(ea[ia] - eb[ib]) <= 6)
						{
						key := Round((sa[ia] + ea[ia]) / 2) . "_" . ya
						if (!used.HasKey(key))
							{
							used[key] := 1
							AqAddBtn(sa[ia], ea[ia], ya, yb)
							}
						}
					ib++
					}
				ia++
				}
			b++
			}
		a++
		}
	AqSortBtns()
	return AqBtnN
}

AqRemember() {
	global AqBtnN, AqBtnCX, AqBtnCY, AqHoverX, AqHoverY, AqHoverOk
	if (AqBtnN >= 1)
		{
		AqHoverX := AqBtnCX[1]
		AqHoverY := AqBtnCY[1]
		AqHoverOk := true
		}
}

AqShiftBetween(ox, on, nx, nn, pitch) {
	if (on < 1 or nn < 1 or pitch < 20)
		return 0
	lo := 3
	hi := Round(pitch * 0.92)
	ds := []
	i := 1
	while (i <= on)
		{
		j := 1
		while (j <= nn)
			{
			d := ox[i] - nx[j]
			if (d >= lo and d <= hi)
				ds.Push(d)
			j++
			}
		i++
		}
	n := ds.MaxIndex()
	if (!n)
		return pitch // 4
	i := 2
	while (i <= n)
		{
		v := ds[i]
		j := i - 1
		while (j >= 1 and ds[j] > v)
			{
			ds[j+1] := ds[j]
			j--
			}
		ds[j+1] := v
		i++
		}
	return ds[(n // 2) + 1]
}

AqAddBtn(s, e, ya, yb) {
	global pAqBits, AqW, AqX0, AqY0
	global AqBtnN, AqBtnCX, AqBtnCY, AqBtnKind, AqBtnW, AqBtnH
	sg := 0
	sn := 0
	x := s
	while (x < e)
		{
		pv := NumGet(pAqBits + 0, (ya*AqW*4) + (x*4), "UInt")
		vb := pv & 0xFF
		vg := (pv >> 8) & 0xFF
		vr := (pv >> 16) & 0xFF
		if (vg >= 240 and vb >= 100 and vb <= 160)
			{
			sg := sg + (vg - vr)
			sn++
			}
		x++
		}
	if (sn < 12)
		return
	gr := sg // sn
	AqBtnN++
	AqBtnCX.Push(AqX0 + ((s + e) // 2))
	AqBtnCY.Push(AqY0 + ((ya + yb) // 2))
	AqBtnKind.Push((gr > 60) ? "buy" : "use")
	if (e - s > AqBtnW)
		AqBtnW := e - s
	if (yb - ya > AqBtnH)
		AqBtnH := yb - ya
}

AqSortBtns() {
	global AqBtnN, AqBtnCX, AqBtnCY, AqBtnKind
	i := 2
	while (i <= AqBtnN)
		{
		j := i
		while (j > 1 and AqBtnCX[j-1] > AqBtnCX[j])
			{
			t := AqBtnCX[j-1]
			AqBtnCX[j-1] := AqBtnCX[j]
			AqBtnCX[j] := t
			t := AqBtnCY[j-1]
			AqBtnCY[j-1] := AqBtnCY[j]
			AqBtnCY[j] := t
			t := AqBtnKind[j-1]
			AqBtnKind[j-1] := AqBtnKind[j]
			AqBtnKind[j] := t
			j--
			}
		i++
		}
}

AqScan() {
	global AqBtnN
	if (!AqGrab())
		return 0
	AqFindAll()
	AqRemember()
	return AqBtnN
}

AqPanelOpen() {
	return (AqScan() > 0)
}

AqPanelSure() {
	tries := 0
	while (tries < 3)
		{
		tries++
		if (AqScan() > 0)
			return true
		Sleep, % Tm(TA("aqpanel", 150))
		}
	return false
}

AqWheel(n, dir) {
	global AqBtnN, AqHoverX, AqHoverY, AqHoverOk
	if (AqBtnN < 1 and !AqHoverOk)
		{
		if (AqScan() < 1)
			return false
		}
	if (!AqHoverOk)
		return false
	hx := AqHoverX
	hy := AqHoverY
	MouseMove, hx, hy
	Sleep, % Tm(TA("aqwh1", 60))
	Loop, %n%
		{
		if (dir > 0)
			Click, WheelDown
		else
			Click, WheelUp
		Sleep, % Tm(TA("aqwh2", 30))
		}
	Sleep, % Tm(TA("aqwh3", 130))
	return true
}

AqRecoverRow() {
	global WindowWidth, WindowHeight, AqHoverX, AqHoverY, AqHoverOk
	AqHoverX := Round(WindowWidth * 0.50)
	AqHoverY := Round(WindowHeight * 0.62)
	AqHoverOk := true
	spent := 0
	Loop, 6
		{
		if (!AqWheel(5, -1))
			break
		spent := spent + 5
		if (AqScan() >= 1)
			return true
		}
	if (spent > 0)
		AqWheel(spent, 1)
	AqHoverOk := false
	return false
}

AqWaitPanel(want) {
	global AquariumOpenDelay
	started := A_TickCount
	cap := AquariumOpenDelay + 3000
	Loop
		{
		Sleep, % Tm(TA("aqpanel", 150))
		now := (AqScan() > 0) ? 1 : 0
		if (now = want)
			return true
		if (A_TickCount - started >= cap)
			return false
		}
}

AqTap(x, y) {
	MouseMove, %x%, %y%
	Sleep, % Tm(TA("aqtap", 55))
	Click
	return
}

AqLeftX() {
	global AqBtnN, AqBtnCX
	return (AqBtnN >= 1) ? AqBtnCX[1] : -99999
}

AqScrollHome() {
	global AquariumScrollSteps, AqBtnN
	tries := 0
	same := 0
	last := -99999
	while (tries < 20)
		{
		tries++
		if (!AqWheel(AquariumScrollSteps, -1))
			return false
		AqScan()
		cur := AqLeftX()
		if (AqBtnN >= 1 and cur = last)
			{
			same++
			if (same >= 1)
				return true
			}
		else
			same := 0
		last := cur
		}
	return true
}

AqMeasurePitch() {
	global AqBtnN, AqBtnCX, AqCardPitch, AqBtnW
	AqCardPitch := 0
	if (AqScan() < 1)
		return false
	if (AqBtnN >= 2)
		{
		best := 0
		i := 2
		while (i <= AqBtnN)
			{
			d := AqBtnCX[i] - AqBtnCX[i-1]
			if (d > best)
				best := d
			i++
			}
		AqCardPitch := best
		}
	if (AqCardPitch < 20)
		AqCardPitch := Round(AqBtnW * 1.15)
	return (AqCardPitch >= 20)
}

NoiseIsCore(pv, cB, cG, cR, ctol) {
	vb := pv & 0xFF
	vg := (pv >> 8) & 0xFF
	vr := (pv >> 16) & 0xFF
	if (Abs(vb - cB) <= ctol and Abs(vg - cG) <= ctol and Abs(vr - cR) <= ctol)
		return true
	if (vg < 34 or vg > 104)
		return false
	if (vr > 52 or vb > 76)
		return false
	if (vg < vr + 10 or vg < vb + 4)
		return false
	vl := (vr + vg + vb) // 3
	if (vl < 14 or vl > 74)
		return false
	return true
}

NfNow() {
	global NfFakeT, QpcFreq
	if (NfFakeT)
		return NfFakeT
	DllCall("QueryPerformanceCounter", "Int64*", t)
	return t
}

NfLoadBlob(hex) {
	if (A_PtrSize != 8)
		return 0
	n := StrLen(hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	return p
}

NfNativeInit() {
	global NfNativeReady, pNfDiffRow, pNfIconHist
	static NfDiffHex := "5356575541544155415641574889CE4889D7418B5904498B691031C04531DB41BCFFFFFFFF41BDFFFFFFFF4439C00F8DAE000000440FB636440FB63F4529FE4585F6790341F7DE4589F2440FB67601440FB67F014529FE4585F6790341F7DE4501F2440FB67602440FB67F024529FE4585F6790341F7DE4501F241D1E34183E30F453B117E044183CB014589DF4183E7014589DE41D1EE4183E6014501F74589DE41C1EE024183E6014501F74589DE41C1EE034183E6014501F74183FF037C154183FC007D0C4189C44183EC0379034531E44189C5FFC04801DE4801DFE949FFFFFF4183FC000F8C8C0000004489E0480FAFC34889CE4801C64889D74801C74531D24531DB31D24489E04439E80F8F48000000440FB636440FB67E010FB64E024501F34501FB4101CB4439F17D034489F14129CF4501FA440FB6374401F2440FB677014401F2440FB677024401F2FFC04801DE4801DFE9AFFFFFFF4489650044896D044489550844895D0C895510B801000000E90200000031C0415F415E415D415C5D5F5E5BC3"
	static NfIconHex := "535657554154415541564157418B19418B69044531ED4183FD030F8DE8000000498B41104589EF440FAFFA41C1E7024889C74C01FF4989FA4189D7456BFF0C4D01FA4531F6453B710C0F8DB10000004489E8410FAF410C4401F0410341080FAFC2C1E0024889CE4801C64531DB41BCFFFFFFFF4139D30F8D5B0000000FB60639D87C200FB6460139D87C180FB6460239D87C104283049F014183FC007D2D4589DCEB284183FC007C224489D84429E039E87C124589E74539DF7D0A438304BA0141FFC7EBF141BCFFFFFFFF41FFC34883C604E99CFFFFFF4183FC007C1B89D04429E039E87C124589E74139D77D0A438304BA0141FFC7EBF141FFC6E945FFFFFF41FFC5E90EFFFFFF415F415E415D415C5D5F5E5BC3"
	if (NfNativeReady)
		return
	NfNativeReady := true
	pNfDiffRow := 0
	pNfIconHist := 0
	p1 := NfLoadBlob(NfDiffHex)
	p2 := NfLoadBlob(NfIconHex)
	VarSetCapacity(prm, 24, 0)
	VarSetCapacity(c1, 40 * 8, 0)
	VarSetCapacity(r1, 40 * 8, 0)
	Loop, 40
		{
		v := Mod(A_Index * 7, 200)
		o := (A_Index - 1) * 8
		NumPut(v, c1, o, "UChar"), NumPut(v + 3, c1, o + 1, "UChar"), NumPut(v + 1, c1, o + 2, "UChar")
		NumPut(v, r1, o, "UChar"), NumPut(v + 3, r1, o + 1, "UChar"), NumPut(v + 1, r1, o + 2, "UChar")
		if (A_Index >= 11 and A_Index <= 20)
			NumPut(v + 90, r1, o, "UChar")
		}
	VarSetCapacity(o1, 24, 0)
	VarSetCapacity(o2, 24, 0)
	NumPut(36, prm, 0, "Int"), NumPut(8, prm, 4, "Int")
	NumPut(&o1, prm, 16, "Int64")
	rvN := p1 ? DllCall(p1, "Ptr", &c1, "Ptr", &r1, "Int", 40, "Ptr", &prm, "Int") : -9
	NumPut(&o2, prm, 16, "Int64")
	rvA := NfDiffRowAhk(&c1, &r1, 40, &prm)
	ok1 := (p1 != 0 and rvN = rvA and rvA = 1)
	Loop, 5
		if (NumGet(o1, (A_Index - 1) * 4, "Int") != NumGet(o2, (A_Index - 1) * 4, "Int"))
			ok1 := false
	if (ok1)
		pNfDiffRow := p1
	w := 30
	h := 12
	VarSetCapacity(img, w * h * 4, 0)
	Loop, % w * h
		{
		x := Mod(A_Index - 1, w)
		y := (A_Index - 1) // w
		v := ((x >= 8 and x <= 18 and y >= 3 and y <= 9) or (x = 24 and y >= 2)) ? 230 : 40
		o := (A_Index - 1) * 4
		NumPut(v, img, o, "UChar"), NumPut(v, img, o + 1, "UChar"), NumPut(v, img, o + 2, "UChar")
		}
	VarSetCapacity(h1, w * 6 * 4, 0)
	VarSetCapacity(h2, w * 6 * 4, 0)
	NumPut(200, prm, 0, "Int"), NumPut(5, prm, 4, "Int"), NumPut(3, prm, 8, "Int"), NumPut(3, prm, 12, "Int")
	NumPut(&h1, prm, 16, "Int64")
	if (p2)
		DllCall(p2, "Ptr", &img, "Int", w, "Int", h, "Ptr", &prm)
	NumPut(&h2, prm, 16, "Int64")
	NfIconHistAhk(&img, w, h, &prm)
	ok2 := (p2 != 0 and NumGet(h2, 12 * 4, "Int") = 3 and NumGet(h2, (3 * w + 12) * 4, "Int") = 3 and NumGet(h2, (3 * w + 24) * 4, "Int") = 0)
	Loop, % w * 6
		if (NumGet(h1, (A_Index - 1) * 4, "Int") != NumGet(h2, (A_Index - 1) * 4, "Int"))
			ok2 := false
	if (ok2)
		pNfIconHist := p2
}

NfDiffRowAhk(pCur, pRef, n, pPrm) {
	T := NumGet(pPrm + 0, 0, "Int")
	step := NumGet(pPrm + 0, 4, "Int")
	pOut := NumGet(pPrm + 0, 16, "Int64")
	sr := 0
	first := -1
	last := -1
	i := 0
	while (i < n)
		{
		o := i * step
		d := Abs(NumGet(pCur + 0, o, "UChar") - NumGet(pRef + 0, o, "UChar")) + Abs(NumGet(pCur + 0, o + 1, "UChar") - NumGet(pRef + 0, o + 1, "UChar")) + Abs(NumGet(pCur + 0, o + 2, "UChar") - NumGet(pRef + 0, o + 2, "UChar"))
		sr := ((sr << 1) & 0xF) | ((d > T) ? 1 : 0)
		if (((sr & 1) + ((sr >> 1) & 1) + ((sr >> 2) & 1) + ((sr >> 3) & 1)) >= 3)
			{
			if (first < 0)
				first := (i >= 3) ? (i - 3) : 0
			last := i
			}
		i++
		}
	if (first < 0)
		return 0
	tint := 0
	sl := 0
	slr := 0
	j := first
	while (j <= last)
		{
		o := j * step
		cb := NumGet(pCur + 0, o, "UChar"), cg := NumGet(pCur + 0, o + 1, "UChar"), cr := NumGet(pCur + 0, o + 2, "UChar")
		tint += cg - ((cb > cr) ? cb : cr)
		sl += cb + cg + cr
		slr += NumGet(pRef + 0, o, "UChar") + NumGet(pRef + 0, o + 1, "UChar") + NumGet(pRef + 0, o + 2, "UChar")
		j++
		}
	NumPut(first, pOut + 0, 0, "Int"), NumPut(last, pOut + 0, 4, "Int"), NumPut(tint, pOut + 0, 8, "Int"), NumPut(sl, pOut + 0, 12, "Int"), NumPut(slr, pOut + 0, 16, "Int")
	return 1
}

NfIconHistAhk(pBits, w, h, pPrm) {
	thr := NumGet(pPrm + 0, 0, "Int")
	minrun := NumGet(pPrm + 0, 4, "Int")
	y0 := NumGet(pPrm + 0, 8, "Int")
	rpb := NumGet(pPrm + 0, 12, "Int")
	pOut := NumGet(pPrm + 0, 16, "Int64")
	band := 0
	while (band < 3)
		{
		pRaw := pOut + band * w * 4
		pSol := pOut + (3 + band) * w * 4
		r := 0
		while (r < rpb)
			{
			y := y0 + band * rpb + r
			q := pBits + y * w * 4
			runS := -1
			x := 0
			while (x < w)
				{
				o := x * 4
				wh := (NumGet(q + 0, o, "UChar") >= thr and NumGet(q + 0, o + 1, "UChar") >= thr and NumGet(q + 0, o + 2, "UChar") >= thr)
				if (wh)
					{
					NumPut(NumGet(pRaw + 0, o, "Int") + 1, pRaw + 0, o, "Int")
					if (runS < 0)
						runS := x
					}
				else if (runS >= 0)
					{
					if (x - runS >= minrun)
						{
						k := runS
						while (k < x)
							{
							NumPut(NumGet(pSol + 0, k * 4, "Int") + 1, pSol + 0, k * 4, "Int")
							k++
							}
						}
					runS := -1
					}
				x++
				}
			if (runS >= 0 and w - runS >= minrun)
				{
				k := runS
				while (k < w)
					{
					NumPut(NumGet(pSol + 0, k * 4, "Int") + 1, pSol + 0, k * 4, "Int")
					k++
					}
				}
			r++
			}
		band++
		}
}

NoiseWarnKind() {
	global pNoteBits, NoteW, NoteH, FishBarLeft, NoteTop, WindowWidth, WindowHeight, QpcFreq
	global NoiseWNow, NfRing, NfRingT, NfRingN, NfRingIdx, NfRowBytes, NfN, NfKS
	global NfNativeReady, NfLatchKind, NfLatchT, NfWhy
	NoiseWNow := ""
	if (!pNoteBits or NoteH < 80 or NoteW < 100)
		return ""
	if (!NfNativeReady)
		NfNativeInit()
	if (!IsObject(NfKS))
		NfKS := [-0.9, -0.8, -0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6, 0.8, 0.9]
	cx := (WindowWidth * 0.5) - FishBarLeft
	cy := (WindowHeight * 0.52) - NoteTop
	R := WindowHeight * 0.139
	x0 := Round(cx - 1.7 * R)
	x1 := Round(cx + 1.7 * R)
	if (x0 < 0)
		x0 := 0
	if (x1 > NoteW - 1)
		x1 := NoteW - 1
	n := (x1 - x0) // 2
	if (n < 60)
		return ""
	rowBytes := n * 8
	if (NfRowBytes != rowBytes or !IsObject(NfRingT))
		{
		NfRowBytes := rowBytes
		VarSetCapacity(NfRing, 32 * 11 * rowBytes, 0)
		NfRingT := []
		NfRingN := 0
		NfRingIdx := 0
		NfLatchKind := ""
		NfLatchT := 0
		}
	now := NfNow()
	slot := NfRingIdx
	if (NfRingN > 0)
		{
		prevSlot := Mod(slot + 31, 32)
		if (((now - NfRingT[prevSlot]) / QpcFreq) < 0.040)
			slot := prevSlot
		}
	i := 0
	while (i < 11)
		{
		y := Round(cy + R * NfKS[i + 1])
		if (y < 0)
			y := 0
		if (y > NoteH - 1)
			y := NoteH - 1
		DllCall("RtlMoveMemory", "Ptr", &NfRing + ((slot * 11 + i) * rowBytes), "Ptr", pNoteBits + ((y * NoteW + x0) * 4), "Ptr", rowBytes)
		i++
		}
	if (slot = NfRingIdx)
		{
		NfRingT[slot] := now
		NfRingIdx := Mod(slot + 1, 32)
		if (NfRingN < 32)
			NfRingN := NfRingN + 1
		}
	kind := NfSingle(strong, weak)
	if (kind != "")
		NfWhy := "single " . kind
	for ri, lo in [0.12, 0.80]
		{
		if (kind != "")
			break
		ref := -1
		s := 0
		while (s < NfRingN)
			{
			if (s != slot)
				{
				age := (now - NfRingT[s]) / QpcFreq
				if (age >= lo and age <= lo + 0.45 and (ref < 0 or NfRingT[s] > NfRingT[ref]))
					ref := s
				}
			s++
			}
		if (ref < 0)
			continue
		kind := NfClassify(slot, ref, n, R, cx - x0, strong)
		if (kind != "")
			break
		}
	if (kind = "")
		return ""
	if (weak)
		{
		if (NfLatchKind != kind or ((now - NfLatchT) / QpcFreq) > 0.4)
			return ""
		NfLatchT := now
		NoiseWNow := kind
		return kind
		}
	latched := strong or (NfLatchKind = kind and ((now - NfLatchT) / QpcFreq) <= 0.4)
	NfLatchKind := kind
	NfLatchT := now
	if (!latched)
		return ""
	NoiseWNow := kind
	return kind
}

NfClassify(slot, ref, n, R, cxs, ByRef strong) {
	global NfRing, NfRowBytes, NfKS, pNfDiffRow, NfPrm, NfOut, NfWhy, NfPrmBuf, NfOutBuf
	strong := false
	if (!NfPrm)
		{
		VarSetCapacity(NfPrmBuf, 24, 0)
		VarSetCapacity(NfOutBuf, 24, 0)
		NfPrm := &NfPrmBuf
		NfOut := &NfOutBuf
		}
	NumPut(36, NfPrm + 0, 0, "Int"), NumPut(8, NfPrm + 0, 4, "Int"), NumPut(NfOut, NfPrm + 0, 16, "Int64")
	w := []
	fl := []
	fr := []
	gchg := 0
	tint := 0
	sl := 0
	slr := 0
	cnt := 0
	mA := Round((cxs - 1.2 * R) / 2)
	mB := Round((cxs + 1.2 * R) / 2)
	lA := 0
	lB := Round((cxs - 1.25 * R) / 2)
	rA := Round((cxs + 1.25 * R) / 2)
	rB := n - 1
	if (mA < 0)
		mA := 0
	if (mB > n - 1)
		mB := n - 1
	if (lB < 4 or rB - rA < 4 or mB - mA < 20)
		return ""
	k := 0
	while (k < 11)
		{
		pc := &NfRing + ((slot * 11 + k) * NfRowBytes)
		pr := &NfRing + ((ref * 11 + k) * NfRowBytes)
		for mi, mo in [lA, rA]
			{
			mn := (mo = lA) ? (lB - lA + 1) : (rB - rA + 1)
			if (pNfDiffRow)
				rv := DllCall(pNfDiffRow, "Ptr", pc + mo * 8, "Ptr", pr + mo * 8, "Int", mn, "Ptr", NfPrm, "Int")
			else
				rv := NfDiffRowAhk(pc + mo * 8, pr + mo * 8, mn, NfPrm)
			if (rv and NumGet(NfOut + 0, 4, "Int") - NumGet(NfOut + 0, 0, "Int") >= 4)
				{
				gchg := gchg + 1
				break
				}
			}
		if (pNfDiffRow)
			rv := DllCall(pNfDiffRow, "Ptr", pc + mA * 8, "Ptr", pr + mA * 8, "Int", mB - mA + 1, "Ptr", NfPrm, "Int")
		else
			rv := NfDiffRowAhk(pc + mA * 8, pr + mA * 8, mB - mA + 1, NfPrm)
		if (rv)
			{
			a := mA + NumGet(NfOut + 0, 0, "Int")
			b := mA + NumGet(NfOut + 0, 4, "Int")
			w[k + 1] := (b - a) * 2 / R
			fl[k + 1] := a
			fr[k + 1] := b
			tint += NumGet(NfOut + 0, 8, "Int")
			sl += NumGet(NfOut + 0, 12, "Int")
			slr += NumGet(NfOut + 0, 16, "Int")
			cnt += b - a + 1
			}
		else
			{
			w[k + 1] := 0
			fl[k + 1] := -1
			fr[k + 1] := -1
			}
		k++
		}
	if (cnt < 1)
		return ""
	if (gchg >= 5)
		{
		if ((sl - slr) / (cnt * 3) > -6)
			return ""
		tok := 0
		bok := 0
		Loop, 3
			{
			if (w[A_Index] <= 1.5)
				tok += 1
			if (w[A_Index + 8] >= 1.9 and w[A_Index + 8] <= 2.3)
				bok += 1
			}
		if (tok < 2 or bok < 2)
			return ""
		}
	shape := NfShape(w)
	gm := tint / cnt
	dl := (sl - slr) / (cnt * 3)
	if (shape = "" and gm >= 40)
		{
		gok := 0
		for i, v in [w[4], w[5], w[6], w[7], w[8]]
			if (v >= 1.5 and v <= 2.4)
				gok := gok + 1
		if (gok >= 3)
			shape := "CIR"
		}
	if (shape = "")
		return ""
	kind := ""
	if (shape = "CIR" and gm >= 25)
		{
		kind := "GREEN"
		strong := (gm >= 45)
		}
	else if (shape = "SQ" and dl >= 10)
		{
		kind := "WHITE"
		strong := (dl >= 20)
		}
	else if (shape = "TRI" and dl <= -6)
		{
		kind := "BLACK"
		strong := (dl <= -15)
		}
	if (kind = "")
		return ""
	if (gchg >= 5)
		{
		if (kind != "BLACK")
			{
			strong := false
			return ""
			}
		gext := 0
		k := 0
		while (k < 11)
			{
			pc := &NfRing + ((slot * 11 + k) * NfRowBytes)
			pr := &NfRing + ((ref * 11 + k) * NfRowBytes)
			for mi, mo in [lA, rA]
				{
				mn := (mo = lA) ? (lB - lA + 1) : (rB - rA + 1)
				if (pNfDiffRow)
					rv := DllCall(pNfDiffRow, "Ptr", pc + mo * 8, "Ptr", pr + mo * 8, "Int", mn, "Ptr", NfPrm, "Int")
				else
					rv := NfDiffRowAhk(pc + mo * 8, pr + mo * 8, mn, NfPrm)
				if (rv and (NumGet(NfOut + 0, 4, "Int") - NumGet(NfOut + 0, 0, "Int") + 1) * 2 >= mn)
					{
					gext := gext + 1
					break
					}
				}
			k++
			}
		if (gext >= 5)
			{
			strong := false
			return ""
			}
		}
	if (kind = "BLACK")
		{
		dk := 0
		tot := 0
		for i, yv in [-0.2, 0.0, 0.2, 0.4, 0.6]
			{
			hw := 0.40 + 0.6 * yv
			pc := &NfRing + ((slot * 11 + i + 3) * NfRowBytes)
			pr := &NfRing + ((ref * 11 + i + 3) * NfRowBytes)
			for j2, sg in [-1, 1]
				{
				ja := Round((cxs + sg * 0.2 * R) / 2)
				jb := Round((cxs + sg * hw * R) / 2)
				j := (ja < jb) ? ja : jb
				je := (ja < jb) ? jb : ja
				while (j <= je)
					{
					o := j * 8
					sc := NumGet(pc + 0, o, "UChar") + NumGet(pc + 0, o + 1, "UChar") + NumGet(pc + 0, o + 2, "UChar")
					sr := NumGet(pr + 0, o, "UChar") + NumGet(pr + 0, o + 1, "UChar") + NumGet(pr + 0, o + 2, "UChar")
					tot += 1
					if (sr - sc >= 36 and sc * 5 <= sr * 4)
						dk += 1
					j += 2
					}
				}
			}
		if (tot < 1 or dk * 10 < tot * 6)
			{
			strong := false
			return ""
			}
		}
	okr := 0
	k := 0
	while (k < 11)
		{
		a := fl[k + 1]
		b := fr[k + 1]
		if (a >= 0 and b - a >= 4)
			{
			pc := &NfRing + ((slot * 11 + k) * NfRowBytes)
			firstHit := -1
			lastHit := -1
			j := a
			while (j <= b)
				{
				o := j * 8
				pb := NumGet(pc + 0, o, "UChar"), pg := NumGet(pc + 0, o + 1, "UChar"), prr := NumGet(pc + 0, o + 2, "UChar")
				mx := (pb > pg) ? pb : pg
				if (prr > mx)
					mx := prr
				mn := (pb < pg) ? pb : pg
				if (prr < mn)
					mn := prr
				if (kind = "BLACK")
					hit := (mx <= 95)
				else if (kind = "WHITE")
					hit := (mn >= 200 and mx - mn <= 40)
				else
					hit := (pg >= 150 and pg - ((pb > prr) ? pb : prr) >= 50)
				if (hit)
					{
					if (firstHit < 0)
						firstHit := j
					lastHit := j
					}
				j++
				}
			if (firstHit >= 0 and (firstHit - a) <= 0.35 * (b - a) and (b - lastHit) <= 0.35 * (b - a))
				okr := okr + 1
			}
		k++
		}
	if (okr < 5)
		{
		strong := false
		return ""
		}
	NfWhy := shape . " g" . Round(gm) . " dL" . Round(dl)
	return kind
}

NfShape(w) {
	global NfKS
	sq := 0
	Loop, 11
		if (w[A_Index] >= 1.9 and w[A_Index] <= 2.3)
			sq := sq + 1
	if (sq >= 9)
		return "SQ"
	cen := [w[4], w[5], w[6], w[7], w[8]]
	cok := 0
	for i, v in cen
		if (v >= 1.75 and v <= 2.3)
			cok := cok + 1
	cmed := NfMedian(cen)
	tnar := (w[1] >= 0.7 and w[1] <= 1.85 and w[2] >= 0.7 and w[2] <= 1.85 and cmed - (w[1] + w[2]) / 2 >= 0.3)
	bnar := (w[10] >= 0.7 and w[10] <= 1.85 and w[11] >= 0.7 and w[11] <= 1.85 and cmed - (w[10] + w[11]) / 2 >= 0.3)
	if (cok >= 3 and (tnar or bnar))
		return "CIR"
	tok := 0
	for i, v in [w[1], w[2], w[3]]
		if (v <= 1.5)
			tok := tok + 1
	bok := 0
	for i, v in [w[9], w[10], w[11]]
		if (v >= 1.9 and v <= 2.3)
			bok := bok + 1
	upm := NfMedian([w[4], w[5]])
	dnm := NfMedian([w[7], w[8]])
	topm := NfMedian([w[1], w[2], w[3]])
	botm := NfMedian([w[9], w[10], w[11]])
	if (tok >= 2 and bok >= 2 and dnm - upm >= 0.15 and botm - topm >= 0.6)
		return "TRI"
	return ""
}

NfMedian(arr) {
	a := []
	for i, v in arr
		a.Push(v)
	nA := a.Length()
	i := 1
	while (i < nA)
		{
		j := i + 1
		while (j <= nA)
			{
			if (a[j] < a[i])
				{
				t := a[i]
				a[i] := a[j]
				a[j] := t
				}
			j++
			}
		i++
		}
	if (Mod(nA, 2) = 1)
		return a[(nA + 1) // 2]
	return (a[nA // 2] + a[nA // 2 + 1]) / 2
}

NfSingle(ByRef strong, ByRef weak) {
	global pNoteBits, NoteW, NoteH, FishBarLeft, NoteTop, WindowWidth, WindowHeight, NfSP, NfSPR
	strong := false
	weak := false
	if (!pNoteBits or NoteH < 80 or NoteW < 100)
		return ""
	R := WindowHeight * 0.139
	cx := (WindowWidth * 0.5) - FishBarLeft
	cy := (WindowHeight * 0.52) - NoteTop
	if (!IsObject(NfSP) or NfSPR != R)
		NfBuildPts(R)
	gi := 0
	for i, p in NfSP.disc
		gi += NfIsGreen(cx + p[1], cy + p[2])
	gi := gi / NfSP.disc.Length()
	if (gi >= 0.7)
		{
		ge := 0
		for i, p in NfSP.edge
			ge += NfIsGreen(cx + p[1], cy + p[2])
		if (ge <= 1)
			{
			strong := (gi >= 0.85)
			return "GREEN"
			}
		}
	wi := 0
	li := 0
	for i, p in NfSP.sq
		{
		v := NfPx(cx + p[1], cy + p[2])
		pb := v & 0xFF, pg := (v >> 8) & 0xFF, pr := (v >> 16) & 0xFF
		l := (pb + pg + pr) / 3
		li += l
		mx := (pb > pg) ? pb : pg
		if (pr > mx)
			mx := pr
		mn := (pb < pg) ? pb : pg
		if (pr < mn)
			mn := pr
		if (l >= 130 and mx - mn <= 50)
			wi += 1
		}
	nS := NfSP.sq.Length()
	li := li / nS
	if (wi / nS >= 0.85)
		{
		lo := 0
		wo := 0
		for i, p in NfSP.sqo
			{
			v := NfPx(cx + p[1], cy + p[2])
			pb := v & 0xFF, pg := (v >> 8) & 0xFF, pr := (v >> 16) & 0xFF
			l := (pb + pg + pr) / 3
			lo += l
			mx := (pb > pg) ? pb : pg
			if (pr > mx)
				mx := pr
			mn := (pb < pg) ? pb : pg
			if (pr < mn)
				mn := pr
			if (l >= 130 and mx - mn <= 50)
				wo += 1
			}
		nO := NfSP.sqo.Length()
		lo := lo / nO
		if (li - lo >= 40 and wo / nO <= 0.5)
			{
			gc := 0
			gs := 0
			for i, yv in [-0.40, -0.30, -0.20]
				{
				gc += NfLum(cx, cy + yv * R)
				gs += NfLum(cx - 0.25 * R, cy + yv * R) + NfLum(cx + 0.25 * R, cy + yv * R)
				}
			if (gs / 6 - gc / 3 >= 12)
				strong := (li - lo >= 80)
			else
				weak := true
			return "WHITE"
			}
		}
	ki := 0
	m := 0
	for i, p in NfSP.tri
		{
		l := NfLum(cx + p[1], cy + p[2])
		m += l
		if (l <= 110)
			ki += 1
		}
	nT := NfSP.tri.Length()
	m := m / nT
	if (ki / nT >= 0.85)
		{
		tout := 0
		for i, p in NfSP.tout
			tout += NfLum(cx + p[1], cy + p[2])
		tout := tout / NfSP.tout.Length()
		sadd := (m * 0.5 > 20) ? m * 0.5 : 20
		if (sadd > 40)
			sadd := 40
		if ((tout >= 50 and m <= 0.70 * tout) or (tout >= 15 and m <= 0.5 * tout))
			{
			side := 0
			for i, p in NfSP.side
				if (NfLum(cx + p[1], cy + p[2]) >= m + sadd)
					side += 1
			corn := 0
			for i, p in NfSP.corn
				if (NfLum(cx + p[1], cy + p[2]) <= 110)
					corn += 1
			if (side >= 4 and corn >= 3)
				{
				gl := 0
				for i, p in NfSP.glyph
					if (NfLum(cx + p[1], cy + p[2]) >= m + 30)
						gl += 1
				if (gl >= 4)
					{
					strong := (m <= 0.55 * tout or (side >= 5 and m <= 0.70 * tout))
					return "BLACK"
					}
				}
			}
		}
	return ""
}

NfPx(x, y) {
	global pNoteBits, NoteW, NoteH
	xx := Round(x)
	yy := Round(y)
	if (xx < 0)
		xx := 0
	if (xx > NoteW - 1)
		xx := NoteW - 1
	if (yy < 0)
		yy := 0
	if (yy > NoteH - 1)
		yy := NoteH - 1
	return NumGet(pNoteBits + 0, ((yy * NoteW) + xx) * 4, "UInt")
}

NfLum(x, y) {
	v := NfPx(x, y)
	return ((v & 0xFF) + ((v >> 8) & 0xFF) + ((v >> 16) & 0xFF)) / 3
}

NfIsGreen(x, y) {
	v := NfPx(x, y)
	pb := v & 0xFF, pg := (v >> 8) & 0xFF, pr := (v >> 16) & 0xFF
	return (pg >= 110 and pg - pr >= 60 and pg - pb >= 15) ? 1 : 0
}

NfBuildPts(R) {
	global NfSP, NfSPR
	NfSPR := R
	NfSP := {disc: [], edge: [], sq: [], sqo: [], tri: [], side: [], corn: [], tout: [], glyph: []}
	yy := -0.8
	while (yy <= 0.81)
		{
		xx := -0.8
		while (xx <= 0.81)
			{
			if (xx * xx + yy * yy <= 0.7225 and Abs(xx) > 0.12)
				NfSP.disc.Push([xx * R, yy * R])
			xx += 0.2
			}
		yy += 0.2
		}
	a := 0
	while (a < 8)
		{
		NfSP.edge.Push([1.12 * R * Cos(a * 0.7853981634), 1.12 * R * Sin(a * 0.7853981634)])
		a++
		}
	yy := -0.75
	while (yy <= 0.76)
		{
		xx := -0.75
		while (xx <= 0.76)
			{
			if (Abs(xx) > 0.15)
				NfSP.sq.Push([xx * R, yy * R])
			xx += 0.25
			}
		yy += 0.25
		}
	v := -0.9
	while (v <= 0.91)
		{
		NfSP.sqo.Push([-1.25 * R, v * R]), NfSP.sqo.Push([1.25 * R, v * R]), NfSP.sqo.Push([v * R, -1.25 * R]), NfSP.sqo.Push([v * R, 1.25 * R])
		v += 0.3
		}
	yy := -0.5
	while (yy <= 0.81)
		{
		hw := 0.65 + 0.5 * yy
		if (hw < 0.05)
			hw := 0.05
		xx := -1.0
		while (xx <= 1.01)
			{
			if (Abs(xx) <= hw - 0.2 and Abs(xx) > 0.15)
				NfSP.tri.Push([xx * R, yy * R])
			xx += 0.2
			}
		yy += 0.2
		}
	for i, yv in [-0.6, -0.35, -0.1]
		{
		hw := 0.65 + 0.5 * yv
		NfSP.side.Push([-(hw + 0.25) * R, yv * R]), NfSP.side.Push([(hw + 0.25) * R, yv * R])
		}
	NfSP.corn := [[-0.65 * R, 0.55 * R], [0.65 * R, 0.55 * R], [-0.45 * R, 0.7 * R], [0.45 * R, 0.7 * R]]
	NfSP.glyph := [[0, -0.40 * R], [0, -0.25 * R], [0, -0.10 * R], [0, 0.05 * R], [0, 0.20 * R], [0, 0.50 * R]
		, [-0.05 * R, -0.20 * R], [0.05 * R, -0.20 * R], [-0.05 * R, 0.10 * R], [0.05 * R, 0.10 * R]]
	NfSP.tout := [[-0.8 * R, -0.85 * R], [0.8 * R, -0.85 * R], [-1.1 * R, -0.5 * R], [1.1 * R, -0.5 * R], [-1.25 * R, 0], [1.25 * R, 0], [-0.45 * R, -1.05 * R], [0.45 * R, -1.05 * R]]
}

NoiseZoneIcons() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, WindowHeight, WindowWidth
	global NoiseZWx, NoiseZGx, NoiseZKx, NfIconN, pNfIconHist, NfNativeReady, NfHist, NfHistW, NfHPrm, NfHistBuf, NfHPrmBuf
	NoiseZWx := -1
	NoiseZGx := -1
	NoiseZKx := -1
	NfIconN := 0
	if (!pCaptureBits or CaptureW < 200 or CaptureH < 12)
		return false
	if (!NfNativeReady)
		NfNativeInit()
	w := CaptureW
	if (NfHistW != w)
		{
		NfHistW := w
		VarSetCapacity(NfHistBuf, w * 6 * 4, 0)
		NfHist := &NfHistBuf
		VarSetCapacity(NfHPrmBuf, 24, 0)
		NfHPrm := &NfHPrmBuf
		}
	D := WindowHeight * 0.018
	minrun := Round(D * 0.25)
	if (minrun < 5)
		minrun := 5
	NfZoneHist(w, 0, CaptureH // 3, minrun)
	cand := []
	sumw := 0
	x := 0
	st := -1
	while (x <= w and cand.Length() < 4)
		{
		on := false
		if (x < w)
			on := (NumGet(NfHist + 0, (3 * w + x) * 4, "Int") + NumGet(NfHist + 0, (4 * w + x) * 4, "Int") + NumGet(NfHist + 0, (5 * w + x) * 4, "Int")) > 0
		if (on and st < 0)
			st := x
		else if (!on and st >= 0)
			{
			wid := x - st
			if (wid >= D * 0.45 and wid <= D * 1.7)
				{
				cand.Push([st, x - 1, -1])
				sumw += wid
				}
			st := -1
			}
		x++
		}
	if (cand.Length() < 2)
		return false
	for i, c in cand
		{
		y := CaptureH - 1
		while (y >= 0)
			{
			run := 0
			best := 0
			off := (y * w + c[1]) * 4
			k := c[1]
			while (k <= c[2])
				{
				px := NumGet(pCaptureBits + 0, off, "UInt")
				if (((px >> 16) & 0xFF) >= 200 and ((px >> 8) & 0xFF) >= 200 and (px & 0xFF) >= 200)
					{
					run += 1
					if (run > best)
						best := run
					}
				else
					run := 0
				off += 4
				k++
				}
			if (best >= minrun)
				break
			y--
			}
		c[3] := y
		}
	ybot := -1
	for i, c in cand
		{
		if (c[3] < 4)
			continue
		agree := 0
		for j, d in cand
			if (j != i and d[3] >= 0 and Abs(d[3] - c[3]) <= 3)
				agree += 1
		if (agree >= 1 and c[3] > ybot)
			ybot := c[3]
		}
	if (ybot < 4)
		return false
	rpb := Round(1.1 * (sumw / cand.Length()) / 3)
	if (rpb < 1)
		rpb := 1
	y0 := ybot - (3 * rpb) + 1
	if (y0 < 0)
		y0 := 0
	NfZoneHist(w, y0, rpb, minrun)
	for i, c in cand
		{
		if (c[3] < 4 or Abs(c[3] - ybot) > 3)
			continue
		cT := 0
		cM := 0
		cB := 0
		k := c[1]
		while (k <= c[2])
			{
			cT += NumGet(NfHist + 0, k * 4, "Int")
			cM += NumGet(NfHist + 0, (w + k) * 4, "Int")
			cB += NumGet(NfHist + 0, (2 * w + k) * 4, "Int")
			k++
			}
		cmax := (cT > cM) ? cT : cM
		if (cB > cmax)
			cmax := cB
		cmin := (cT < cM) ? cT : cM
		if (cB < cmin)
			cmin := cB
		if (cmax < 1)
			continue
		kind := ""
		if (cT <= 0.45 * cB)
			kind := "TRI"
		else if (cmin >= 0.75 * cmax)
			kind := "SQ"
		else if (cT >= 0.35 * cM and cT <= 0.75 * cM and cB >= 0.45 * cM and cB <= 0.90 * cM)
			kind := "CIR"
		cx := Round(FishBarLeft + (c[1] + c[2]) / 2)
		sep := WindowWidth * 0.035
		if ((NoiseZWx >= 0 and Abs(cx - NoiseZWx) < sep) or (NoiseZGx >= 0 and Abs(cx - NoiseZGx) < sep) or (NoiseZKx >= 0 and Abs(cx - NoiseZKx) < sep))
			continue
		if (kind = "SQ" and NoiseZWx < 0)
			NoiseZWx := cx
		else if (kind = "CIR" and NoiseZGx < 0)
			NoiseZGx := cx
		else if (kind = "TRI" and NoiseZKx < 0)
			NoiseZKx := cx
		}
	NfIconN := (NoiseZWx >= 0) + (NoiseZGx >= 0) + (NoiseZKx >= 0)
	return (NfIconN >= 2)
}

NfZoneHist(w, y0, rpb, minrun) {
	global pCaptureBits, CaptureH, pNfIconHist, NfHist, NfHPrm
	DllCall("RtlZeroMemory", "Ptr", NfHist, "Ptr", w * 6 * 4)
	NumPut(200, NfHPrm + 0, 0, "Int"), NumPut(minrun, NfHPrm + 0, 4, "Int"), NumPut(y0, NfHPrm + 0, 8, "Int"), NumPut(rpb, NfHPrm + 0, 12, "Int"), NumPut(NfHist, NfHPrm + 0, 16, "Int64")
	if (pNfIconHist)
		DllCall(pNfIconHist, "Ptr", pCaptureBits, "Int", w, "Int", CaptureH, "Ptr", NfHPrm)
	else
		NfIconHistAhk(pCaptureBits, w, CaptureH, NfHPrm)
}


HalibutCircleX() {
	global QpcFreq, HaliLastX, HaliLastT
	DllCall("QueryPerformanceCounter", "Int64*", hnow)
	hx := HalibutFindCircle()
	if (hx >= 0)
		{
		HaliLastX := hx
		HaliLastT := hnow
		return hx
		}
	if (HaliLastT and ((hnow - HaliLastT) / QpcFreq) < 0.15)
		return HaliLastX
	HaliLastT := 0
	return -1
}

HalibutBlue(px) {
	b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
	return (b >= 90 and b - r >= 45 and b - g >= 45 and r <= 90 and g <= 90)
}

HalibutFindCircle() {
	global pNoteBits, NoteW, NoteH, FishBarLeft, WindowHeight
	if (!pNoteBits or NoteH < 20 or NoteW < 20)
		return -1
	D := WindowHeight * 0.040
	gapMax := Round(D * 0.3)
	for ri, fr in [0.55, 0.45, 0.65]
		{
		p := pNoteBits + (Round(NoteH * fr) * NoteW * 4)
		runS := -1
		runE := -1
		x := 0
		while (x < NoteW + gapMax + 2)
			{
			if (x < NoteW and HalibutBlue(NumGet(p + 0, x * 4, "UInt")))
				{
				if (runS < 0)
					runS := x
				runE := x
				}
			else if (runS >= 0 and (x - runE > gapMax))
				{
				w := runE - runS + 1
				if (w >= D * 0.35 and w <= D * 1.5)
					{
					cx := HalibutVerify(runS, runE, D)
					if (cx >= 0)
						return FishBarLeft + cx
					}
				runS := -1
				}
			x += 2
			}
		}
	return -1
}

HalibutVerify(s, e, D) {
	global pNoteBits, NoteW, NoteH
	x0 := s - Round(D * 0.3)
	x1 := e + Round(D * 0.3)
	if (x0 < 0)
		x0 := 0
	if (x1 > NoteW - 1)
		x1 := NoteW - 1
	n := 0, minX := 99999, maxX := -1, minY := 99999, maxY := -1
	y := 0
	while (y < NoteH)
		{
		p := pNoteBits + (y * NoteW * 4)
		x := x0
		while (x <= x1)
			{
			if (HalibutBlue(NumGet(p + 0, x * 4, "UInt")))
				{
				n++
				if (x < minX)
					minX := x
				if (x > maxX)
					maxX := x
				if (y < minY)
					minY := y
				maxY := y
				}
			x += 2
			}
		y += 2
		}
	if (n < 4)
		return -1
	w := maxX - minX + 2
	h := maxY - minY + 2
	if (w < D * 0.45 or w > D * 1.4 or h < D * 0.45 or h > D * 1.4)
		return -1
	if (Abs(w - h) > 0.3 * ((w > h) ? w : h))
		return -1
	if ((n * 4) / (0.7854 * w * h) < 0.6)
		return -1
	cy := (minY + maxY) / 2
	if (cy < NoteH * 0.3 or cy > NoteH * 0.8 or maxY >= NoteH - 3)
		return -1
	return (minX + maxX) / 2
}

NoiseGimmickTarget() {
	global QpcFreq, NoiseZoneTgt, NoiseZoneT, NoiseZoneKind
	global NoiseZScanT, NoiseZWx, NoiseZGx, NoiseZKx, NoiseZOK, NoiseZFreshT
	global NoisePendKind, NoisePendT, NoiseZPrevOK, NoiseOnZoneN
	global WindowWidth, NfIconN, NfCW, NfCG, NfCK, NfPW, NfPG, NfPK, NfGoneN
	DllCall("QueryPerformanceCounter", "Int64*", gnow)
	gk := NoiseWarnKind()
	seq := (NoisePendT > 0 and ((gnow - NoisePendT) / QpcFreq) < 2.0)
	if (gk != "")
		{
		if (gk != "BLACK")
			{
			NoisePendKind := gk
			NoisePendT := gnow
			}
		else if (NoisePendKind = "" or NoisePendKind = "BLACK" or !seq)
			{
			NoisePendKind := "BLACK"
			NoisePendT := gnow
			}
		}
	pend := (NoisePendT > 0 and ((gnow - NoisePendT) / QpcFreq) < 2.20)
	zgone := false
	gint := 1.00
	if (pend or NoiseZoneTgt >= 0)
		gint := 0.15
	if (NoiseZScanT < 1 or ((gnow - NoiseZScanT) / QpcFreq) >= gint)
		{
		NoiseZScanT := gnow
		NoiseZoneIcons()
		tolX := WindowWidth * 0.015
		one := (NfIconN = 3)
		NfCW := (NoiseZWx >= 0 and (one or (NfPW >= 0 and Abs(NoiseZWx - NfPW) <= tolX))) ? NoiseZWx : -1
		NfCG := (NoiseZGx >= 0 and (one or (NfPG >= 0 and Abs(NoiseZGx - NfPG) <= tolX))) ? NoiseZGx : -1
		NfCK := (NoiseZKx >= 0 and (one or (NfPK >= 0 and Abs(NoiseZKx - NfPK) <= tolX))) ? NoiseZKx : -1
		NfPW := NoiseZWx
		NfPG := NoiseZGx
		NfPK := NoiseZKx
		if (NfIconN >= 2)
			{
			NoiseZFreshT := gnow
			NfGoneN := 0
			}
		else if (NoiseZoneTgt >= 0 and ((gnow - NoiseZoneT) / QpcFreq) >= 1.2)
			{
			NfGoneN := NfGoneN + 1
			if (NfGoneN >= 2)
				zgone := true
			}
		}
	NoiseZPrevOK := NoiseZOK
	NoiseZOK := (NoiseZFreshT > 0 and ((gnow - NoiseZFreshT) / QpcFreq) < 0.60)
	if (NoiseZoneTgt >= 0)
		{
		zage := (gnow - NoiseZoneT) / QpcFreq
		zgap := (NoiseZFreshT > 0) ? ((gnow - NoiseZFreshT) / QpcFreq) : 99
		if (!zgone and zage < 1.85 and zgap < 1.00)
			return NoiseZoneTgt
		if (!zgone and zage < 4.00 and NoiseZOK)
			return NoiseZoneTgt
		NoiseZoneTgt := -1
		NoiseZoneKind := ""
		NoisePendKind := ""
		NoisePendT := 0
		}
	if (!pend or !NoiseZOK)
		return -1
	gz := -1
	if (NoisePendKind = "WHITE")
		gz := NfCW
	else if (NoisePendKind = "GREEN")
		gz := NfCG
	else if (NoisePendKind = "BLACK")
		gz := NfCK
	if (gz < 0)
		return -1
	NoiseZoneTgt := gz
	NoiseZoneT := gnow
	NfGoneN := 0
	NoiseZoneKind := NoisePendKind
	NoisePendT := 0
	return gz
}
PinionPlan(fishX, noteX, ByRef isNote) {
	global RunLeft, RunWidth, WindowWidth, WindowHeight, QpcFreq, NoteBias
	global NoteLockY, NoteH, NoteFresh, NoteAllN
	global PnState, PnImpactAt, PnCoverX, PnNoteX, PnFall, PnFallN, PnPrevY, PnPrevT, PnPrevX, PnProg, PnWhy
	global PnRes, PnGlueAt, PnGlueLo, PnGlueHi, PnAwayAt, PnTwoN, PnResBlockUntil
	global PnSeenY, PnSeenAt, PnLandAt, PnLeaveAt, PnGone, NoteMissAt, NoteAllX, NoteAllY, NoteOriginX
	isNote := false
	DllCall("QueryPerformanceCounter", "Int64*", pnNow)
	p := PinProgress()
	if (p >= 0)
		PnProg := p
	if (RunWidth <= 0)
		return fishX
	halfW := RunWidth / 2
	barC := RunLeft + halfW
	margin := RunWidth * 0.30
	if (margin < 14)
		margin := 14
	reach := halfW - margin
	if (reach < 4)
		reach := 4
	if (fishX >= 0)
		{
		if (Abs(fishX - barC) <= WindowWidth * 0.010)
			{
			if (!PnGlueAt)
				{
				PnGlueAt := pnNow
				PnGlueLo := barC
				PnGlueHi := barC
				}
			if (barC < PnGlueLo)
				PnGlueLo := barC
			if (barC > PnGlueHi)
				PnGlueHi := barC
			}
		else
			PnGlueAt := 0
		if (Abs(fishX - barC) > WindowWidth * 0.06)
			{
			if (!PnAwayAt)
				PnAwayAt := pnNow
			}
		else
			PnAwayAt := 0
		}
	if (NoteFresh)
		{
		vDrop := (PnFallN >= 3 and PnFall > 0) ? PnFall : (WindowHeight * 0.60)
		twoOk := (NoteAllN >= 2)
		if (twoOk and fishX >= 0)
			{
			twoI := 1
			while (twoI <= NoteAllN)
				{
				if (NoteAllY[twoI] >= NoteH - WindowHeight * 0.07 and Abs((NoteOriginX + NoteAllX[twoI]) - fishX) <= WindowWidth * 0.02)
					twoOk := false
				twoI++
				}
			}
		PnTwoN := twoOk ? (PnTwoN + 1) : 0
		if ((PnState = 1 or PnRes) and PnNoteX >= 0)
			{
			if (!NoteMissAt and NoteLockY >= 0 and noteX >= 0 and Abs(noteX - PnNoteX) <= 60 and NoteLockY > PnSeenY)
				{
				PnGone := false
				PnSeenY := NoteLockY
				PnSeenAt := pnNow
				PnPrevY := NoteLockY
				PnPrevT := pnNow
				PnPrevX := noteX
				PnLandAt := pnNow + Round(((NoteH - NoteLockY) / vDrop) * QpcFreq)
				PnLeaveAt := PnLandAt + Round(0.08 * QpcFreq)
				landAt := PnLandAt + Round(0.15 * QpcFreq)
				if (landAt > PnImpactAt)
					PnImpactAt := landAt
				}
			else if (NoteMissAt or noteX < 0 or Abs(noteX - PnNoteX) > 60 or NoteLockY < PnSeenY or (pnNow - PnSeenAt) >= 0.06 * QpcFreq)
				PnGone := true
			}
		}
	if (!PnRes)
		{
		if (PnGlueAt and ((pnNow - PnGlueAt) / QpcFreq) >= 0.30 and (PnGlueHi - PnGlueLo) >= WindowWidth * 0.08)
			PnRes := 1
		else if (PnTwoN >= 3 and fishX >= 0 and Abs(fishX - barC) <= WindowWidth * 0.03 and pnNow >= PnResBlockUntil)
			PnRes := 1
		if (PnRes)
			{
			PnState := 0
			PnNoteX := -1
			PnGone := false
			}
		}
	else if (PnAwayAt and ((pnNow - PnAwayAt) / QpcFreq) >= 0.25)
		{
		PnRes := 0
		PnGlueAt := 0
		PnTwoN := 0
		PnNoteX := -1
		PnGone := false
		PnResBlockUntil := pnNow + Round(1.5 * QpcFreq)
		}
	if (PnRes)
		{
		if (noteX >= 0)
			{
			if (NoteFresh and !NoteMissAt and NoteLockY >= 0 and (PnNoteX < 0 or Abs(noteX - PnNoteX) > 60 or NoteLockY < PnSeenY))
				{
				PnNoteX := noteX
				PnSeenY := NoteLockY
				PnSeenAt := pnNow
				PnLandAt := pnNow + Round(((NoteH - NoteLockY) / vDrop) * QpcFreq)
				PnLeaveAt := PnLandAt + Round(0.08 * QpcFreq)
				PnGone := false
				}
			if (!PnGone or pnNow < PnLeaveAt)
				{
				isNote := true
				PnWhy := "resonance: note"
				return noteX
				}
			PnWhy := "resonance: no note"
			return (fishX >= 0) ? fishX : barC
			}
		PnNoteX := -1
		PnGone := false
		PnWhy := "resonance: no note"
		return (fishX >= 0) ? fishX : barC
		}
	if (PnState = 1)
		{
		if (pnNow >= PnImpactAt or (PnGone and pnNow >= PnLeaveAt))
			PnState := 0
		else
			{
			if (fishX >= 0)
				{
				if (fishX >= PnNoteX - reach and fishX <= PnNoteX + reach)
					PnCoverX := fishX
				else
					PnCoverX := PnNoteX
				}
			isNote := (PnCoverX != fishX and Abs(barC - PnCoverX) <= NoteHoldZone(RunWidth))
			PnWhy := "hold"
			return PnCoverX
			}
		}
	if (noteX < 0 or NoteBias <= 0)
		{
		PnWhy := "no note"
		return fishX
		}
	if (NoteFresh and NoteLockY >= 0 and !(NoteMissAt and Abs(noteX - PnNoteX) <= 60 and pnNow >= PnLeaveAt))
		{
		if (PnPrevT and Abs(noteX - PnPrevX) <= 60 and NoteLockY > PnPrevY)
			{
			dtS := (pnNow - PnPrevT) / QpcFreq
			if (dtS > 0.02 and dtS < 0.4)
				{
				v := (NoteLockY - PnPrevY) / dtS
				if (v < WindowHeight * 0.45)
					v := WindowHeight * 0.45
				if (v > WindowHeight * 0.80)
					v := WindowHeight * 0.80
				PnFall := (PnFall > 0) ? (PnFall * 0.8 + v * 0.2) : v
				PnFallN := PnFallN + 1
				}
			}
		PnPrevY := NoteLockY
		PnPrevT := pnNow
		PnPrevX := noteX
		}
	if (NoteLockY < 0 or !PnPrevT)
		return fishX
	vFall := (PnFallN >= 3 and PnFall > 0) ? PnFall : (WindowHeight * 0.60)
	tti := (NoteH - NoteLockY) / vFall - ((pnNow - PnPrevT) / QpcFreq)
	if (tti < -0.05)
		{
		PnWhy := "no note"
		return fishX
		}
	if (fishX >= 0 and fishX >= noteX - reach and fishX <= noteX + reach)
		cover := fishX
	else
		cover := noteX
	vBar := WindowWidth * 0.30
	tGo := Abs(cover - barC) / vBar
	if (tGo + 0.15 > tti + 0.05)
		{
		PnWhy := "skip: too far"
		return fishX
		}
	tTravel := tGo + 0.90
	if (fishX >= 0 and cover != fishX)
		{
		tOff := tti + Abs(cover - fishX) / vBar + 0.10
		floor := 0.12 + (100 - NoteBias) * 0.005
		if (PnProg >= 0)
			{
			if (PnProg - 0.092 * tOff < floor)
				{
				PnWhy := "skip: progress " . Round(PnProg * 100) . "%"
				return fishX
				}
			}
		else if (tOff > 1.6)
			{
			PnWhy := "skip: progress unknown"
			return fishX
			}
		}
	if (tti > tTravel + 0.10)
		{
		PnWhy := "wait " . Round(tti - tTravel, 1) . "s"
		return fishX
		}
	PnState := 1
	PnNoteX := noteX
	PnCoverX := cover
	PnSeenY := NoteLockY
	PnSeenAt := PnPrevT
	PnGone := false
	PnLandAt := pnNow + Round(tti * QpcFreq)
	PnLeaveAt := PnLandAt + Round(0.08 * QpcFreq)
	PnImpactAt := PnLandAt + Round(0.15 * QpcFreq)
	isNote := (cover != fishX and Abs(barC - cover) <= NoteHoldZone(RunWidth))
	PnWhy := "go " . Round(Abs(cover - barC)) . "px"
	return cover
}

PinProgress() {
	global pCaptureBits, CaptureW, PnProgRow, PnPrmW, PnPrmWI, PnPrmP, PnPrmPI
	if (!pCaptureBits or PnProgRow < 4 or CaptureW < 40)
		return -1
	best := -1
	bestN := 0
	r := PnProgRow - 4
	while (r <= PnProgRow + 4)
		{
		p := pCaptureBits + (r * CaptureW * 4)
		ww := 0
		pw := 0
		i0 := PcFind(p, CaptureW, 4, PnPrmW)
		if (i0 >= 0)
			{
			i1 := PcFind(p + (i0 + 1) * 4, CaptureW - i0 - 1, 4, PnPrmWI)
			ww := (i1 < 0) ? (CaptureW - i0) : (i1 + 1)
			j0 := PcFind(p + (i0 + ww) * 4, CaptureW - i0 - ww, 4, PnPrmP)
			if (j0 >= 0 and j0 <= 6)
				{
				js := i0 + ww + j0
				j1 := PcFind(p + (js + 1) * 4, CaptureW - js - 1, 4, PnPrmPI)
				pw := (j1 < 0) ? (CaptureW - js) : (j1 + 1)
				}
			}
		else
			{
			j0 := PcFind(p, CaptureW, 4, PnPrmP)
			if (j0 >= 0)
				{
				j1 := PcFind(p + (j0 + 1) * 4, CaptureW - j0 - 1, 4, PnPrmPI)
				pw := (j1 < 0) ? (CaptureW - j0) : (j1 + 1)
				}
			}
		if (ww + pw > bestN)
			{
			bestN := ww + pw
			best := ww / (ww + pw)
			}
		r += 2
		}
	if (bestN < CaptureW * 0.15)
		return -1
	return best
}

NoteTarget() {
	global SpecialRod, RunLeft, RunWidth, NoteDbgRod, HalibutPlayMinigame
	NoteDbgRod := NoteDbgRod + 1
	if (SpecialRod = "Noiseform")
		return NoiseGimmickTarget()
	if (SpecialRod = "Halibut Harpoon")
		return HalibutPlayMinigame ? HalibutCircleX() : -1
	if (SpecialRod != "Pinions Aria")
		return -1
	ref := (RunWidth > 0) ? RunLeft + (RunWidth / 2) : -1
	return NoteScan(ref)
}

FindBarRelative() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, BarScanRow
	global RunLeft, RunWidth, RelBarL, RelBarR, RelBarRow
	row := BarScanRow
	if (row < 0 or row >= CaptureH)
		row := CaptureH // 2
	rowOff := row * CaptureW * 4
	sum := 0
	mx := 0
	x := 0
	while (x < CaptureW)
		{
		px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
		l := ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
		sum += l
		if (l > mx)
			mx := l
		x++
		}
	avg := sum // CaptureW
	thr := (mx - avg) * 35 // 100
	if (thr < 30)
		thr := 30
	thr += avg
	if (mx < thr)
		return false
	bestW := 0
	bestS := -1
	bestE := -1
	runS := -1
	runE := -1
	gap := 0
	x := 0
	while (x < CaptureW)
		{
		px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
		l := ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
		if (l >= thr)
			{
			if (runS < 0)
				runS := x
			runE := x
			gap := 0
			}
		else if (runS >= 0)
			{
			gap++
			if (gap > 4)
				{
				if (runE - runS + 1 > bestW)
					{
					bestW := runE - runS + 1
					bestS := runS
					bestE := runE
					}
				runS := -1
				gap := 0
				}
			}
		x++
		}
	if (runS >= 0 and runE - runS + 1 > bestW)
		{
		bestW := runE - runS + 1
		bestS := runS
		bestE := runE
		}
	if (bestW < 8 or bestW > CaptureW * 0.6)
		return false
	RunLeft := FishBarLeft + bestS
	RunWidth := bestW
	RelBarL := bestS
	RelBarR := bestE
	RelBarRow := row
	return true
}

FindFishRelative() {
	global pCaptureBits, CaptureW, FishBarLeft, RelBarL, RelBarR, RelBarRow, LastFishX
	if (RelBarR - RelBarL < 20)
		return -1
	rowOff := RelBarRow * CaptureW * 4
	sumB := 0
	sumG := 0
	sumR := 0
	n := 0
	x := RelBarL
	while (x <= RelBarR)
		{
		px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
		sumB += px & 0xFF
		sumG += (px >> 8) & 0xFF
		sumR += (px >> 16) & 0xFF
		n++
		x++
		}
	mB := sumB // n
	mG := sumG // n
	mR := sumR // n
	madSum := 0
	x := RelBarL
	while (x <= RelBarR)
		{
		px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
		madSum += Abs((px & 0xFF) - mB) + Abs(((px >> 8) & 0xFF) - mG) + Abs(((px >> 16) & 0xFF) - mR)
		x++
		}
	thr := (madSum // n) * 3
	if (thr < 16)
		thr := 16
	bestScore := 0
	bestS := -1
	bestE := -1
	runS := -1
	runE := -1
	runSum := 0
	x := RelBarL
	while (x <= RelBarR)
		{
		px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
		d := Abs((px & 0xFF) - mB) + Abs(((px >> 8) & 0xFF) - mG) + Abs(((px >> 16) & 0xFF) - mR)
		if (d >= thr)
			{
			if (runS < 0)
				{
				runS := x
				runSum := 0
				}
			runE := x
			runSum += d
			}
		else if (runS >= 0)
			{
			if (runE - runS + 1 <= 25 and runSum > bestScore)
				{
				bestScore := runSum
				bestS := runS
				bestE := runE
				}
			runS := -1
			}
		x++
		}
	if (runS >= 0 and runE - runS + 1 <= 25 and runSum > bestScore)
		{
		bestScore := runSum
		bestS := runS
		bestE := runE
		}
	if (bestS < 0)
		return -1
	fx := FishBarLeft + ((bestS + bestE) / 2)
	LastFishX := fx
	return fx
}

BarWPush(w) {
	global BarWRing, BarWMed
	if (!IsObject(BarWRing))
		BarWRing := []
	BarWRing.Push(w)
	if (BarWRing.MaxIndex() > 5)
		BarWRing.RemoveAt(1)
	n := BarWRing.MaxIndex()
	srt := []
	Loop, %n%
		srt.Push(BarWRing[A_Index])
	i := 2
	while (i <= n)
		{
		v := srt[i]
		j := i - 1
		while (j >= 1 and srt[j] > v)
			{
			srt[j+1] := srt[j]
			j--
			}
		srt[j+1] := v
		i++
		}
	BarWMed := srt[(n // 2) + 1]
}

BarPresent() {
	global BarLeftColor, BarRightColor, BarScanRow, RelLock, SpecialRod, PinFishX
	global ControlMode, LineBarL, LineBarW, RunLeft, RunWidth, LineFishSeen, NoiseBarL, NoiseBarW
	global BarWidthTrusted, CastBarL, CastBarW, RemBarL, RemBarW, MiguBarL, MiguBarW, HaliBarL, HaliBarW
	global VgBarL, VgBarW, TryBarL, TryBarW, SwFound, SwBarL, SwBarW
	BarWidthTrusted := true
	if (SpecialRod = "Stellarwave Melody")
		{
		if (SwScan() and SwFound)
			{
			RunLeft := SwBarL
			RunWidth := SwBarW
			return true
			}
		return false
		}
	if (SpecialRod = "Castbound")
		{
		if (CastboundScan())
			{
			RunLeft := CastBarL
			RunWidth := CastBarW
			return true
			}
		return false
		}
	if (SpecialRod = "Noiseform")
		{
		if (NoiseScan())
			{
			RunLeft := NoiseBarL
			RunWidth := NoiseBarW
			return true
			}
		return false
		}
	if (SpecialRod = "Remembrance")
		{
		if (RemBarScan())
			{
			RunLeft := RemBarL
			RunWidth := RemBarW
			return true
			}
		return false
		}
	if (SpecialRod = "MiguRod")
		{
		if (MiguBarScan())
			{
			RunLeft := MiguBarL
			RunWidth := MiguBarW
			return true
			}
		return false
		}
	if (SpecialRod = "Halibut Harpoon")
		{
		if (HalibutBarScan())
			{
			RunLeft := HaliBarL
			RunWidth := HaliBarW
			return true
			}
		return false
		}
	if (SpecialRod = "Tryhard Rod")
		{
		if (TryhardScan())
			{
			RunLeft := TryBarL
			RunWidth := TryBarW
			return true
			}
		return false
		}
	if (ControlMode = "Lines")
		{
		if (LineScan())
			{
			RunLeft := LineBarL
			RunWidth := LineBarW
			return true
			}
		if (LineFishSeen and LineBarW >= 1)
			{
			RunLeft := LineBarL
			RunWidth := LineBarW
			return true
			}
		return false
		}
	if (SpecialRod = "Verdant Oath")
		{
		if (VerdantBarScan())
			{
			RunLeft := VgBarL
			RunWidth := VgBarW
			return true
			}
		return false
		}
	if (SpecialRod = "Pinions Aria")
		{
		PinionScan()
		if (LineScan())
			{
			RunLeft := LineBarL
			RunWidth := LineBarW
			return true
			}
		if (LineFishSeen and LineBarW >= 1)
			{
			RunLeft := LineBarL
			RunWidth := LineBarW
			return true
			}
		return false
		}
	if (BarLeftColor != "" and BarRightColor != "" and RelLock != 1)
		{
		if (FindBarByColor())
			{
			RelLock := 2
			return true
			}
		if (RelLock = 2)
			return false
		}
	if (RelLock != 2)
		{
		ok := FindBarRelative()
		if (ok and RelLock = 0 and FindFishRelative() >= 0)
			RelLock := 1
		if (RelLock = 1)
			return ok
		}
	BarWidthTrusted := false
	if (ScanRowBar(BarScanRow, 6))
		return true
	return CalibrateBarRow(6)
}

FindArrowX() {
	global ArrowColor, ArrowColorTolerance, CaptureW, CaptureH, BarScanRow
	if (ArrowColor = "")
		return -1
	tol := ArrowColorTolerance
	if (tol < 8)
		tol := 8
	aList := ColorListParse(ArrowColor)
	if (aList.n < 1)
		return -1
	row := BarScanRow
	if (row < 0 or row >= CaptureH)
		row := CaptureH // 2
	ax := ColorListCenterX(aList, tol, row, 0, CaptureW - 1)
	if (ax >= 0)
		return ax
	Loop, 5
		{
		y2 := Floor(CaptureH * (A_Index*2 - 1) / 10)
		ax := ColorListCenterX(aList, tol, y2, 0, CaptureW - 1)
		if (ax >= 0)
			return ax
		}
	return -1
}

FishLineVisible() {
	global pCaptureBits, CaptureW, CaptureH, FishColor, FishBarColorTolerance, BarScanRow
	global ControlMode, LineFishSeen, SpecialRod, CastFishX, RemWhiteX, MiguFishX, HaliFishX, TryFishX, SwFishX
	if (SpecialRod = "Stellarwave Melody")
		return (SwScan() and SwFishX >= 0)
	if (SpecialRod = "Castbound")
		{
		CastboundScan()
		return (CastFishX >= 0)
		}
	if (SpecialRod = "Halibut Harpoon")
		return (HalibutBarScan() and HaliFishX >= 0)
	if (SpecialRod = "Remembrance")
		{
		RemembranceScan()
		return (RemWhiteX >= 0)
		}
	if (SpecialRod = "MiguRod")
		{
		MiguScan()
		return (MiguFishX >= 0 and BarPresent())
		}
	if (SpecialRod = "Tryhard Rod")
		return (TryhardScan() and TryFishX >= 0)
	if (ControlMode = "Lines")
		{
		LineScan()
		return LineFishSeen
		}
	if (SpecialRod = "Verdant Oath")
		return (VerdantFishX() >= 0 and VerdantBarScan())
	fList := ColorListParse(FishColor)
	if (fList.n < 1)
		return false
	tol := FishBarColorTolerance
	row := BarScanRow
	if (row < 0 or row >= CaptureH)
		row := CaptureH // 2
	rowOffset := row * CaptureW * 4
	x := 0
	while (x < CaptureW)
		{
		if (ColorListHitPx(fList, NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt"), tol))
			{
			runStart := x
			while (x < CaptureW)
				{
				if (!ColorListHitPx(fList, NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt"), tol))
					break
				x++
				}
			runLen := x - runStart
			if (runLen > 25)
				continue
			cx := runStart + (runLen // 2)
			hits := 0
			Loop, 7
				{
				y2 := Floor(CaptureH * (A_Index*2 - 1) / 14)
				if (y2 >= CaptureH)
					y2 := CaptureH - 1
				if (ColorListHitPx(fList, NumGet(pCaptureBits + 0, (y2*CaptureW*4) + (cx*4), "UInt"), tol))
					hits++
				}
			if (hits >= 5)
				return true
			continue
			}
		x++
		}
	return false
}

MedianOf(arr) {
	n := arr.MaxIndex()
	if (!n)
		return 0
	vals := []
	for i, v in arr
		vals.Push(v)
	i := 2
	while (i <= n)
		{
		key := vals[i]
		j := i - 1
		while (j >= 1 and vals[j] > key)
			{
			vals[j+1] := vals[j]
			j--
			}
		vals[j+1] := key
		i++
		}
	mid := (n // 2) + 1
	if (Mod(n, 2) = 0)
		return (vals[n//2] + vals[(n//2)+1]) / 2
	return vals[mid]
}

; ---- Single-row bounded scans -------------------------------------------------------------

ScanRowFirst(targetBGR, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (y < 0 or y >= CaptureH)
		return -1
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	tB := (targetBGR >> 16) & 0xFF
	tG := (targetBGR >> 8) & 0xFF
	tR := targetBGR & 0xFF
	rowOffset := y * CaptureW * 4
	x := xFrom
	while (x <= xTo)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		if (Abs((px & 0xFF) - tB) <= tol and Abs(((px >> 8) & 0xFF) - tG) <= tol and Abs(((px >> 16) & 0xFF) - tR) <= tol)
			return FishBarLeft + x
		x++
		}
	return -1
}

ScanRowLast(targetBGR, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (y < 0 or y >= CaptureH)
		return -1
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	tB := (targetBGR >> 16) & 0xFF
	tG := (targetBGR >> 8) & 0xFF
	tR := targetBGR & 0xFF
	rowOffset := y * CaptureW * 4
	x := xTo
	while (x >= xFrom)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		if (Abs((px & 0xFF) - tB) <= tol and Abs(((px >> 8) & 0xFF) - tG) <= tol and Abs(((px >> 16) & 0xFF) - tR) <= tol)
			return FishBarLeft + x
		x--
		}
	return -1
}

ScanRowCenter(targetBGR, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (y < 0 or y >= CaptureH)
		return -1
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	tB := (targetBGR >> 16) & 0xFF
	tG := (targetBGR >> 8) & 0xFF
	tR := targetBGR & 0xFF
	rowOffset := y * CaptureW * 4
	runStart := -1
	runEnd := -1
	x := xFrom
	while (x <= xTo)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		if (Abs((px & 0xFF) - tB) <= tol and Abs(((px >> 8) & 0xFF) - tG) <= tol and Abs(((px >> 16) & 0xFF) - tR) <= tol)
			{
			if (runStart < 0)
				runStart := x
			runEnd := x
			}
		else if (runStart >= 0 and (x - runEnd) > 4)
			break
		x++
		}
	if (runStart < 0)
		return -1
	return FishBarLeft + ((runStart + runEnd) / 2)
}


ColorListParse(s) {
	global ColorListCache, ColorListCacheN
	if (!IsObject(ColorListCache))
		{
		ColorListCache := {}
		ColorListCacheN := 0
		}
	if (ColorListCache.HasKey(s))
		return ColorListCache[s]
	if (ColorListCacheN > 96)
		{
		ColorListCache := {}
		ColorListCacheN := 0
		}
	o := {n: 0, r: [], g: [], b: []}
	Loop, Parse, s, `,;| , %A_Space%%A_Tab%
		{
		v := ColNorm(A_LoopField)
		if (v < 0)
			continue
		o.n := o.n + 1
		o.r.Push((v >> 16) & 0xFF)
		o.g.Push((v >> 8) & 0xFF)
		o.b.Push(v & 0xFF)
		}
	ColorListCache[s] := o
	ColorListCacheN := ColorListCacheN + 1
	return o
}

ColMain(s) {
	o := ColorListParse(s)
	if (o.n < 1)
		return 0
	return (o.r[1] << 16) | (o.g[1] << 8) | o.b[1]
}

ColCount(s) {
	o := ColorListParse(s)
	return o.n
}

ColorListHitPx(o, px, tol) {
	pb := px & 0xFF
	pg := (px >> 8) & 0xFF
	pr := (px >> 16) & 0xFF
	i := 1
	n := o.n
	while (i <= n)
		{
		if (Abs(pr - o.r[i]) <= tol and Abs(pg - o.g[i]) <= tol and Abs(pb - o.b[i]) <= tol)
			return true
		i++
		}
	return false
}

ColorListFirstX(o, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (o.n < 1 or y < 0 or y >= CaptureH)
		return -1
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	rowOffset := y * CaptureW * 4
	x := xFrom
	while (x <= xTo)
		{
		if (ColorListHitPx(o, NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt"), tol))
			return FishBarLeft + x
		x++
		}
	return -1
}

ColorListLastX(o, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (o.n < 1 or y < 0 or y >= CaptureH)
		return -1
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	rowOffset := y * CaptureW * 4
	x := xTo
	while (x >= xFrom)
		{
		if (ColorListHitPx(o, NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt"), tol))
			return FishBarLeft + x
		x--
		}
	return -1
}

ColorListLineX(o, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (o.n < 1 or y < 0 or y >= CaptureH)
		return -1
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	rowOffset := y * CaptureW * 4
	x := xFrom
	while (x <= xTo)
		{
		if (!ColorListHitPx(o, NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt"), tol))
			{
			x++
			continue
			}
		runStart := x
		while (x <= xTo and ColorListHitPx(o, NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt"), tol))
			x++
		runLen := x - runStart
		if (runLen <= 25)
			{
			cx := runStart + (runLen // 2)
			hits := 0
			Loop, 7
				{
				y2 := Floor(CaptureH * (A_Index*2 - 1) / 14)
				if (y2 >= CaptureH)
					y2 := CaptureH - 1
				if (ColorListHitPx(o, NumGet(pCaptureBits + 0, (y2*CaptureW*4) + (cx*4), "UInt"), tol))
					hits++
				}
			if (hits >= 5)
				return FishBarLeft + cx
			}
		}
	return -1
}

ColorListCenterX(o, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (o.n < 1 or y < 0 or y >= CaptureH)
		return -1
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	rowOffset := y * CaptureW * 4
	runStart := -1
	runEnd := -1
	x := xFrom
	while (x <= xTo)
		{
		if (ColorListHitPx(o, NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt"), tol))
			{
			if (runStart < 0)
				runStart := x
			runEnd := x
			}
		else if (runStart >= 0 and (x - runEnd) > 4)
			break
		x++
		}
	if (runStart < 0)
		return -1
	return FishBarLeft + ((runStart + runEnd) / 2)
}

; ---- Color-free structural bar detector -----------------------------------------------------

StructBar() {
	global CaptureW, CaptureH, RunLeft, RunWidth, BarScanRow, BarRowAgreement
	if (CaptureW < 24 or CaptureH < 4)
		return false
	nRows := 9
	if (CaptureH < nRows)
		nRows := CaptureH
	ls := []
	ws := []
	cs := []
	ys := []
	Loop, % nRows
		{
		y := Floor(CaptureH * (A_Index*2 - 1) / (nRows*2))
		if (y < 0)
			y := 0
		if (y >= CaptureH)
			y := CaptureH - 1
		if (!ScanRowBar(y, 8))
			continue
		if (RunWidth < CaptureW * 0.05 or RunWidth > CaptureW * 0.72)
			continue
		ls.Push(RunLeft)
		ws.Push(RunWidth)
		cs.Push(RunLeft + RunWidth/2)
		ys.Push(y)
		}
	cnt := cs.MaxIndex()
	if (!cnt)
		cnt := 0
	if (cnt < 4)
		{
		BarRowAgreement := cnt
		return false
		}
	mc := MedianOf(cs)
	mw := MedianOf(ws)
	agree := 0
	bi := 0
	bd := 999999
	for i, c in cs
		{
		if (Abs(c - mc) <= CaptureW * 0.10 and ws[i] >= mw*0.6 and ws[i] <= mw*1.6)
			{
			agree++
			d := Abs(c - mc)
			if (d < bd)
				{
				bd := d
				bi := i
				}
			}
		}
	BarRowAgreement := agree
	if (agree < 4 or !bi)
		return false
	RunLeft := ls[bi]
	RunWidth := ws[bi]
	BarScanRow := ys[bi]
	return true
}


StripSig() {
	global pCaptureBits, CaptureW, CaptureH
	if (!pCaptureBits or CaptureW < 4 or CaptureH < 1)
		return 0
	sg := 0
	yN := 3
	Loop, % yN
		{
		y := Floor(CaptureH * (A_Index*2 - 1) / (yN*2))
		if (y < 0)
			y := 0
		if (y >= CaptureH)
			y := CaptureH - 1
		off := y * CaptureW * 4
		x := 0
		while (x < CaptureW)
			{
			sg := sg + ((NumGet(pCaptureBits + 0, off + (x*4), "UInt") & 0xFFFFFF) * (x + 1))
			x += 3
			}
		}
	return sg
}

; ---- Minigame presence, scored 0-100 ---------------------------------------------------------

NoteHoldZone(w) {
	z := w * 0.20
	if (z < 10)
		z := 10
	return z
}

MgDetect() {
	global SpecialRod, CaptureW, RunWidth
	global MgSawBar, MgSawFish, MgSawArrow, MgConf
	MgSawBar := false
	MgSawFish := false
	MgSawArrow := false
	if (SpecialRod = "Tranquility")
		{
		MgSawFish := ManiaVisible()
		MgConf := MgSawFish ? 80 : 0
		return MgConf
		}
	sc := 0
	if (FishLineVisible())
		{
		MgSawFish := true
		sc += 55
		}
	if (MinigameVisible(6))
		{
		MgSawBar := true
		sc += 40
		}
	if (sc = 0 and FindArrowX() >= 0)
		{
		MgSawArrow := true
		sc := 30
		}
	if (MgSawBar and RunWidth > 10 and RunWidth < CaptureW * 0.7)
		sc += 5
	if (sc > 100)
		sc := 100
	MgConf := sc
	return sc
}

MgAccumulate() {
	global MgScore
	c := MgDetect()
	if (c >= 90)
		{
		MgScore := 6
		return true
		}
	if (c >= 55)
		MgScore := MgScore + 2
	else if (c >= 30)
		MgScore := MgScore + 1
	else
		MgScore := MgScore - 2
	if (MgScore < 0)
		MgScore := 0
	if (MgScore > 6)
		MgScore := 6
	return (MgScore >= 4)
}

BarByEdges() {
	global RunLeft, RunWidth, LineBarL, LineBarW, LastBarL, LastBarR, CaptureW, MgInPlay
	if (!MgInPlay)
		return false
	if (!LineScan())
		return false
	if (LineBarW < 8 or LineBarW > CaptureW * 0.92)
		return false
	RunLeft := LineBarL
	RunWidth := LineBarW
	LastBarL := LineBarL
	LastBarR := LineBarL + LineBarW - 1
	return true
}

BarSpanFill(lList, rList, tol, y, xFrom, xTo) {
	global pCaptureBits, CaptureW, CaptureH
	if (y < 0 or y >= CaptureH or xTo <= xFrom)
		return 0
	if (xFrom < 0)
		xFrom := 0
	if (xTo > CaptureW - 1)
		xTo := CaptureW - 1
	rowOffset := y * CaptureW * 4
	n := 0
	m := 0
	x := xFrom
	while (x <= xTo)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		n++
		if (ColorListHitPx(lList, px, tol) or ColorListHitPx(rList, px, tol))
			m++
		x += 3
		}
	return (n > 0) ? (m / n) : 0
}

;
RemBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, RemembranceMode
	global RemBarScanned, RemBarFound, RemBarL, RemBarW, RemBarRing
	if (RemBarScanned)
		return RemBarFound
	RemBarScanned := true
	RemBarFound := false
	if (CaptureW < 40 or CaptureH < 6)
		return false
	if (RemembranceMode = "Departed")
		{
		bLo := 55
		bHi := 110
		}
	else
		{
		bLo := 145
		bHi := 235
		}
	bRows := [Floor(CaptureH * 0.2), Floor(CaptureH * 0.5), Floor(CaptureH * 0.8)]
	VarSetCapacity(bHits, CaptureW, 0)
	for bI, bY in bRows
		{
		bOff := bY * CaptureW * 4
		bX := 0
		while (bX < CaptureW)
			{
			bP := NumGet(pCaptureBits + 0, bOff + (bX*4), "UInt")
			bB := bP & 0xFF
			bG := (bP >> 8) & 0xFF
			bR := (bP >> 16) & 0xFF
			if (Abs(bR - bG) <= 10 and Abs(bG - bB) <= 10)
				{
				bLum := (bR + bG + bB) // 3
				if (bLum >= bLo and bLum <= bHi)
					NumPut(NumGet(bHits, bX, "UChar") + 1, bHits, bX, "UChar")
				}
			bX++
			}
		}
	bMinRef := Round(CaptureW * 0.08)
	bMaxRef := Round(CaptureW * 0.35)
	if (!IsObject(RemBarRing))
		RemBarRing := []
	bHaveRef := (RemBarRing.MaxIndex() >= 3)
	bRef := bHaveRef ? Round(MedianOf(RemBarRing)) : Round(CaptureW * 0.206)
	bAccLo := bHaveRef ? Round(bRef * 0.7) : bMinRef
	bAccHi := bHaveRef ? Round(bRef * 1.3) : bMaxRef
	bGap := Round(CaptureW * 0.018)
	if (bGap < 6)
		bGap := 6
	bBestL := -1
	bBestLen := 0
	bRunS := -1
	bLast := -1
	bX := 0
	while (bX <= CaptureW)
		{
		bOn := false
		if (bX < CaptureW)
			bOn := (NumGet(bHits, bX, "UChar") >= 2)
		if (bOn)
			{
			if (bRunS < 0)
				bRunS := bX
			bLast := bX
			}
		else if (bRunS >= 0 and ((bX - bLast) > bGap or bX = CaptureW))
			{
			if ((bLast - bRunS + 1) > bBestLen)
				{
				bBestLen := bLast - bRunS + 1
				bBestL := bRunS
				}
			bRunS := -1
			}
		bX++
		}
	if (bBestL >= 0 and bBestLen >= bAccLo and bBestLen <= bAccHi)
		{
		RemBarL := FishBarLeft + bBestL
		RemBarW := bBestLen
		RemBarRing.Push(bBestLen)
		if (RemBarRing.MaxIndex() > 5)
			RemBarRing.RemoveAt(1)
		RemBarFound := true
		return true
		}
	bSum := 0
	bBest := -1
	bBestSum := 0
	bX := 0
	while (bX < CaptureW)
		{
		bSum := bSum + NumGet(bHits, bX, "UChar")
		if (bX >= bRef)
			bSum := bSum - NumGet(bHits, bX - bRef, "UChar")
		if (bX >= bRef - 1 and bSum > bBestSum)
			{
			bBestSum := bSum
			bBest := bX - bRef + 1
			}
		bX++
		}
	if (bBest < 0 or bBestSum < bRef * 3 * 0.45)
		return false
	RemBarL := FishBarLeft + bBest
	RemBarW := bRef
	RemBarFound := true
	return true
}

RemembranceScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, BarScanRow
	global FishColor, FishBarColorTolerance
	global RemWhiteX, RemBlackX, RemTargetX, RemScanned, RemFound
	if (RemScanned)
		return RemFound
	RemScanned := true
	RemFound := false
	RemWhiteX := -1
	RemBlackX := -1
	RemTargetX := -1
	if (CaptureW < 40 or CaptureH < 6)
		return false

	rRows := []
	Loop, 5
		{
		ry := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (ry >= CaptureH)
			ry := CaptureH - 1
		rRows.Push(ry)
		}

	wList := ColorListParse(FishColor)
	if (wList.n < 1)
		wList := ColorListParse("0xFFFFFF")
	wR := wList.r[1]
	wG := wList.g[1]
	wB := wList.b[1]
	wTol := FishBarColorTolerance
	if (wTol < 6)
		wTol := 6
	wMaxW := Round(CaptureW * 0.03)
	if (wMaxW < 8)
		wMaxW := 8
	wBestX := -1
	wBestV := 0
	for wPass, wRowI in [3, 2, 4]
		{
		wRy := rRows[wRowI]
		wOff := wRy * CaptureW * 4
		wRunS := -1
		wX := 0
		while (wX <= CaptureW)
			{
			wHit := false
			if (wX < CaptureW)
				{
				wPx := NumGet(pCaptureBits + 0, wOff + (wX*4), "UInt")
				wHit := (Abs(((wPx >> 16) & 0xFF) - wR) <= wTol and Abs(((wPx >> 8) & 0xFF) - wG) <= wTol and Abs((wPx & 0xFF) - wB) <= wTol)
				}
			if (wHit)
				{
				if (wRunS < 0)
					wRunS := wX
				}
			else if (wRunS >= 0)
				{
				wRunW := wX - wRunS
				if (wRunW >= 2 and wRunW <= wMaxW)
					{
					wCx := wRunS + (wRunW // 2)
					wVotes := 0
					for rI, ry in rRows
						{
						if (RemWhiteAt(wCx, ry, wR, wG, wB, wTol))
							wVotes++
						}
					if (wVotes > wBestV)
						{
						wBestV := wVotes
						wBestX := wCx
						}
					}
				wRunS := -1
				}
			wX++
			}
		if (wBestV >= 4)
			break
		}
	if (wBestV < 4)
		return false
	RemWhiteX := FishBarLeft + wBestX

	rOff := Round(CaptureW * 0.02)
	if (rOff < 8)
		rOff := 8
	bX := -1
	bV := 0
	rx := rOff
	while (rx < CaptureW - rOff)
		{
		if (IsDarkNotch(rx, BarScanRow, rOff))
			{
			rVotes := 0
			for rI, ry in rRows
				{
				if (IsDarkNotch(rx, ry, rOff))
					rVotes++
				}
			if (rVotes >= 3 and rVotes > bV)
				{
				bV := rVotes
				bX := rx
				}
			}
		rx++
		}
	if (bX >= 0)
		RemBlackX := FishBarLeft + bX

	RemFound := true
	RemTargetX := RemAimX(RemWhiteX, RemBlackX)
	return true
}

RemWhiteAt(hx, hy, hr, hg, hb, htol) {
	global pCaptureBits, CaptureW, CaptureH
	if (hy < 0 or hy >= CaptureH)
		return false
	hOff := hy * CaptureW * 4
	hI := hx - 5
	if (hI < 0)
		hI := 0
	hE := hx + 5
	if (hE > CaptureW - 1)
		hE := CaptureW - 1
	while (hI <= hE)
		{
		hP := NumGet(pCaptureBits + 0, hOff + (hI*4), "UInt")
		if (Abs(((hP >> 16) & 0xFF) - hr) <= htol and Abs(((hP >> 8) & 0xFF) - hg) <= htol and Abs((hP & 0xFF) - hb) <= htol)
			return true
		hI++
		}
	return false
}

RemAimX(wx, bx) {
	global RunWidth, RemembranceMode
	rHalf := RunWidth / 2
	if (rHalf < 4 or bx < 0)
		return wx
	rDep := (RemembranceMode = "Departed")
	rClear := rHalf + (rDep ? (RunWidth * 0.15) : (RunWidth * 0.06))
	if (Abs(bx - wx) > rClear + rHalf)
		return wx
	if (bx > wx)
		{
		rAim := bx - rClear
		if (!rDep)
			{
			rLo := wx - rHalf + 2
			if (rAim < rLo)
				rAim := rLo
			}
		return rAim
		}
	rAim := bx + rClear
	if (!rDep)
		{
		rHi := wx + rHalf - 2
		if (rAim > rHi)
			rAim := rHi
		}
	return rAim
}

HalibutBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global HaliBarScanned, HaliBarFound, HaliBarL, HaliBarW, HaliFishX
	if (HaliBarScanned)
		return HaliBarFound
	HaliBarScanned := true
	HaliBarFound := false
	HaliFishX := -1
	if (CaptureW < 40 or CaptureH < 8)
		return false
	hRows := [Floor(CaptureH * 0.28), Floor(CaptureH * 0.38), Floor(CaptureH * 0.78), Floor(CaptureH * 0.88)]
	VarSetCapacity(hBar, CaptureW, 0)
	VarSetCapacity(hDark, CaptureW, 0)
	hTrk := 0
	for hI, hY in hRows
		{
		p := pCaptureBits + (hY * CaptureW * 4)
		x := 0
		while (x < CaptureW)
			{
			px := NumGet(p + 0, x * 4, "UInt"), b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
			if (Abs(r - 0x53) <= 12 and Abs(g - 0x48) <= 12 and Abs(b - 0xA0) <= 14)
				NumPut(NumGet(hBar, x, "UChar") + 1, hBar, x, "UChar")
			else if (Abs(r - 0x2A) <= 12 and Abs(g - 0x26) <= 12 and Abs(b - 0x75) <= 14)
				hTrk++
			else
				{
				mx := (r > g) ? r : g
				mx := (b > mx) ? b : mx
				mn := (r < g) ? r : g
				mn := (b < mn) ? b : mn
				if (mx < 60 and mx - mn <= 10)
					NumPut(NumGet(hDark, x, "UChar") + 1, hDark, x, "UChar")
				}
			x++
			}
		}
	if (hTrk < CaptureW * 0.6)
		return false

	hGap := Round(CaptureW * 0.03)
	if (hGap < 12)
		hGap := 12
	hBestL := -1, hBestLen := 0, hRunS := -1, hLast := -1
	x := 0
	while (x <= CaptureW)
		{
		if (x < CaptureW and NumGet(hBar, x, "UChar") >= 2)
			{
			if (hRunS < 0)
				hRunS := x
			hLast := x
			}
		else if (hRunS >= 0 and ((x - hLast) > hGap or x = CaptureW))
			{
			if ((hLast - hRunS + 1) > hBestLen)
				{
				hBestLen := hLast - hRunS + 1
				hBestL := hRunS
				}
			hRunS := -1
			}
		x++
		}

	hMaxFW := Round(CaptureW * 0.02)
	if (hMaxFW < 12)
		hMaxFW := 12
	hBestHits := 0, hRunS := -1, hHits := 0
	x := 0
	while (x <= CaptureW)
		{
		hd := (x < CaptureW) ? NumGet(hDark, x, "UChar") : 0
		if (hd >= 2)
			{
			if (hRunS < 0)
				hRunS := x, hHits := 0
			hHits += hd
			}
		else if (hRunS >= 0)
			{
			if ((x - hRunS) <= hMaxFW and hHits > hBestHits)
				{
				hBestHits := hHits
				HaliFishX := FishBarLeft + ((hRunS + x - 1) / 2)
				}
			hRunS := -1
			}
		x++
		}

	if (hBestL < 0 or hBestLen < CaptureW * 0.08 or hBestLen > CaptureW * 0.85)
		return false
	HaliBarL := FishBarLeft + hBestL
	HaliBarW := hBestLen
	HaliBarFound := true
	return true
}

TryRowRuns(p, ByRef prm, ByRef prmI, gap, rr) {
	global CaptureW
	x := 0
	n := 0
	s0 := -1
	e0 := -1
	while (x < CaptureW and n < 40)
		{
		s := PcFind(p + x * 4, CaptureW - x, 4, prm)
		if (s < 0)
			break
		s += x
		e := PcFind(p + (s + 1) * 4, CaptureW - s - 1, 4, prmI)
		e := (e < 0) ? CaptureW - 1 : s + e
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

TryTrackAt(x) {
	global pCaptureBits, CaptureW, CaptureH
	if (x < 0 or x >= CaptureW)
		return false
	tkN := 0
	for tkI, tkY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tkPx := NumGet(pCaptureBits + (tkY * CaptureW + x) * 4, 0, "UInt")
		tkB := tkPx & 0xFF
		tkG := (tkPx >> 8) & 0xFF
		tkR := (tkPx >> 16) & 0xFF
		if (tkR + 16 >= tkB and tkR < 70 and tkB < 70 and (tkG < 40 or (tkG < 48 and tkR >= tkG)))
			tkN++
		}
	return (tkN >= 2)
}

TryTrackPx(px) {
	tpB := px & 0xFF
	tpG := (px >> 8) & 0xFF
	tpR := (px >> 16) & 0xFF
	return (tpR + 16 >= tpB and tpR < 70 and tpB < 70 and tpG >= 18 and (tpG < 40 or (tpG < 48 and tpR >= tpG)))
}

TryGapBright(p, a, b) {
	global CaptureW
	if (a > b or b - a + 1 > CaptureW * 0.06)
		return false
	gbN := b - a + 1
	gbHi := 0
	while (a <= b)
		{
		if (((NumGet(p + a * 4, 0, "UInt") >> 16) & 0xFF) >= 140)
			gbHi++
		a++
		}
	return (gbHi = gbN or (gbN <= CaptureW * 0.03 and gbHi >= 2 and gbHi * 5 >= gbN))
}

TryhardScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, WindowHeight, LastFishX
	global TryScanned, TryFound, TryFishX, TryBarL, TryBarW, TryPrmReady
	global TryPrm1, TryPrm1I, TryPrm2, TryPrm2I, TryPrm3, TryPrm3I, TryPrmF, TryPrmFI, TryPrmT, TryPrmTI
	global TryhardBarColors, TryhardFishColors, TryhardTrackColors
	if ((TryhardBarColors != "" or TryhardFishColors != "" or TryhardTrackColors != "")
		and ColCount(TryhardBarColors) + ColCount(TryhardFishColors) + ColCount(TryhardTrackColors) > 0)
		return TryhardScanX()
	if (TryScanned)
		return TryFound
	TryScanned := true
	TryFound := false
	TryFishX := -1
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return false
	if (!TryPrmReady)
		{
		PcSetPrm(TryPrm1, "0x33030B", 14, 0, 0)
		PcSetPrm(TryPrm1I, "0x33030B", 14, 0, 1)
		PcSetPrm(TryPrm2, "0x5F020A", 30, 0, 0)
		PcSetPrm(TryPrm2I, "0x5F020A", 30, 0, 1)
		PcSetPrm(TryPrm3, "0xBE0C0E", 66, 0, 0)
		PcSetPrm(TryPrm3I, "0xBE0C0E", 66, 0, 1)
		PcSetPrm(TryPrmF, "0x2F020C", 14, 0, 0)
		PcSetPrm(TryPrmFI, "0x2F020C", 14, 0, 1)
		PcSetPrm(TryPrmT, "0x3A0608", 14, 0, 0)
		PcSetPrm(TryPrmTI, "0x3A0608", 14, 0, 1)
		TryPrmReady := true
		}
	tfMaxW := Round(CaptureW * 0.02)
	tfNear := Round(CaptureW * 0.003) + 1
	tfC := []
	for tfI, tfO in [Round(WindowHeight * 0.0028), Round(WindowHeight * 0.0049), Round(WindowHeight * 0.0069)]
		{
		if (tfO < 1 or tfO > 17)
			continue
		tfR := []
		TryRowRuns(pCaptureBits - tfO * CaptureW * 4, TryPrmF, TryPrmFI, 1, tfR)
		for tfK, tfV in tfR
			{
			if (tfV[2] - tfV[1] + 1 >= 3 and tfV[2] - tfV[1] + 1 <= tfMaxW)
				tfC.Push([(tfV[1] + tfV[2]) / 2, tfI])
			}
		}
	tfBest := -1
	tfBestD := 999999
	for tfK, tfV in tfC
		{
		tfSeen := 1 << tfV[2]
		for tfK2, tfV2 in tfC
			{
			if (Abs(tfV2[1] - tfV[1]) <= tfNear)
				tfSeen := tfSeen | (1 << tfV2[2])
			}
		if (((tfSeen >> 1) & 1) + ((tfSeen >> 2) & 1) + ((tfSeen >> 3) & 1) >= 2)
			{
			tfD := (LastFishX >= 0) ? Abs(FishBarLeft + tfV[1] - LastFishX) : Abs(tfV[1] - CaptureW / 2)
			if (tfD < tfBestD)
				{
				tfBestD := tfD
				tfBest := tfV[1]
				}
			}
		}
	if (tfBest >= 0)
		{
		TryFishX := FishBarLeft + tfBest
		LastFishX := TryFishX
		}
	tbGap := Round(CaptureW * 0.006)
	tbMinW := Round(CaptureW * 0.02)
	if (tbMinW < 12)
		tbMinW := 12
	tbLs := []
	tbRs := []
	for tbI, tbY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tbP := pCaptureBits + tbY * CaptureW * 4
		tbR := []
		TryRowRuns(tbP, TryPrm1, TryPrm1I, 0, tbR)
		TryRowRuns(tbP, TryPrm2, TryPrm2I, 0, tbR)
		TryRowRuns(tbP, TryPrm3, TryPrm3I, 0, tbR)
		tbJ := 2
		while (tbJ <= tbR.Length())
			{
			tbV := tbR[tbJ]
			tbK := tbJ - 1
			while (tbK >= 1 and tbR[tbK][1] > tbV[1])
				{
				tbR[tbK + 1] := tbR[tbK]
				tbK--
				}
			tbR[tbK + 1] := tbV
			tbJ++
			}
		tbA := -1
		tbB := -1
		tbS := -1
		tbE := -1
		for tbK, tbV in tbR
			{
			if (tbS >= 0 and (tbV[1] - tbE - 1 <= tbGap or TryGapBright(tbP, tbE + 1, tbV[1] - 1)))
				{
				if (tbV[2] > tbE)
					tbE := tbV[2]
				}
			else
				{
				if (tbS >= 0 and tbE - tbS > tbB - tbA)
					{
					tbA := tbS
					tbB := tbE
					}
				tbS := tbV[1]
				tbE := tbV[2]
				}
			}
		if (tbS >= 0 and tbE - tbS > tbB - tbA)
			{
			tbA := tbS
			tbB := tbE
			}
		if (tbA >= 0 and tbB - tbA + 1 >= tbMinW and tbB - tbA + 1 <= CaptureW * 0.6)
			{
			tbLs.Push(tbA)
			tbRs.Push(tbB)
			}
		}
	if (tbLs.Length() < 2)
		return false
	tbA := (tbLs.Length() = 3) ? MedianOf(tbLs) : ((tbLs[1] > tbLs[2]) ? tbLs[1] : tbLs[2])
	tbB := (tbRs.Length() = 3) ? MedianOf(tbRs) : ((tbRs[1] < tbRs[2]) ? tbRs[1] : tbRs[2])
	tbO := Round(CaptureW * 0.006) + 2
	tbTL := TryTrackAt(tbA - tbO)
	tbTR := TryTrackAt(tbB + tbO)
	if (!(tbTL or tbA - tbO < 0) or !(tbTR or tbB + tbO >= CaptureW) or !(tbTL or tbTR))
		return false
	if (tfBest >= 0)
		{
		tbP := pCaptureBits + Floor(CaptureH * 0.50) * CaptureW * 4
		tbSum := 0
		Loop, 8
			tbSum += (NumGet(tbP + Round(tbA + (tbB - tbA) * (A_Index + 1) / 10) * 4, 0, "UInt") >> 16) & 0xFF
		if (tbSum <= 8 * 90)
			{
			tbPh := Round(CaptureW * 0.006)
			if (tfBest >= tbA - tbPh and tfBest <= tbA + tbPh + 2)
				tbA := Round(tfBest + tbPh + 1)
			else if (tfBest >= tbB - tbPh - 2 and tfBest <= tbB + tbPh)
				tbB := Round(tfBest - tbPh - 1)
			}
		}
	if (tbB - tbA + 1 < tbMinW)
		return false
	if (tfBest < 0)
		{
		tqC := []
		for tqI, tqY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			tqP := pCaptureBits + tqY * CaptureW * 4
			tqSum := 0
			tqN := 0
			tqX := tbA + 2
			while (tqX <= tbB - 2)
				{
				tqPx := NumGet(tqP + tqX * 4, 0, "UInt")
				tqR := (tqPx >> 16) & 0xFF
				if (tqR > ((tqPx >> 8) & 0xFF) + 60 and tqR > (tqPx & 0xFF) + 60)
					{
					tqSum += tqR
					tqN++
					}
				tqX++
				}
			if (tqN < 8)
				continue
			tqRef := tqSum / tqN
			if (tqRef < 110)
				continue
			tqS := -1
			tqX := tbA + 2
			while (tqX <= tbB - 1)
				{
				tqPx := (tqX <= tbB - 2) ? NumGet(tqP + tqX * 4, 0, "UInt") : 0xFFFFFF
				tqR := (tqPx >> 16) & 0xFF
				tqD := (tqR < tqRef * 0.72 and ((tqPx >> 8) & 0xFF) < 40 and (tqPx & 0xFF) < 40)
				if (tqD and tqS < 0)
					tqS := tqX
				else if (!tqD and tqS >= 0)
					{
					if (tqX - tqS >= 3 and tqX - tqS <= tfMaxW)
						tqC.Push([(tqS + tqX - 1) / 2, tqI, (tqS <= tbA + 2 or tqX >= tbB - 1) ? 100000 : 0])
					tqS := -1
					}
				tqX++
				}
			}
		tqBestD := 999999
		for tqK, tqV in tqC
			{
			tqSeen := 1 << tqV[2]
			for tqK2, tqV2 in tqC
				{
				if (Abs(tqV2[1] - tqV[1]) <= tfNear)
					tqSeen := tqSeen | (1 << tqV2[2])
				}
			if (((tqSeen >> 1) & 1) + ((tqSeen >> 2) & 1) + ((tqSeen >> 3) & 1) >= 2)
				{
				tqD := (LastFishX >= 0) ? Abs(FishBarLeft + tqV[1] - LastFishX) + tqV[3] : Abs(tqV[1] - (tbA + tbB) / 2) + tqV[3]
				if (tqD < tqBestD)
					{
					tqBestD := tqD
					tfBest := tqV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	if (tfBest < 0)
		{
		ttC := []
		ttK := Round(CaptureW * 0.003) + 2
		for ttI, ttY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			ttP := pCaptureBits + ttY * CaptureW * 4
			ttR := []
			TryRowRuns(ttP, TryPrmT, TryPrmTI, 1, ttR)
			for ttJ, ttV in ttR
				{
				if (ttV[2] - ttV[1] + 1 < 2 or ttV[2] - ttV[1] + 1 > tfMaxW)
					continue
				if (ttV[2] >= tbA - tbO and ttV[1] <= tbB + tbO)
					continue
				if (ttV[1] - ttK < 0 or ttV[2] + ttK >= CaptureW)
					continue
				if (TryTrackPx(NumGet(ttP + (ttV[1] - ttK) * 4, 0, "UInt")) and TryTrackPx(NumGet(ttP + (ttV[2] + ttK) * 4, 0, "UInt")))
					ttC.Push([(ttV[1] + ttV[2]) / 2, ttI])
				}
			}
		ttBestD := 999999
		for ttJ, ttV in ttC
			{
			ttSeen := 1 << ttV[2]
			for ttJ2, ttV2 in ttC
				{
				if (Abs(ttV2[1] - ttV[1]) <= tfNear)
					ttSeen := ttSeen | (1 << ttV2[2])
				}
			if (((ttSeen >> 1) & 1) + ((ttSeen >> 2) & 1) + ((ttSeen >> 3) & 1) >= 2)
				{
				ttD := (LastFishX >= 0) ? Abs(FishBarLeft + ttV[1] - LastFishX) : Abs(ttV[1] - (tbA + tbB) / 2)
				if (ttD < ttBestD)
					{
					ttBestD := ttD
					tfBest := ttV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	TryBarL := FishBarLeft + tbA
	TryBarW := tbB - tbA + 1
	TryFound := true
	return true
}

TryhardScanX() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, WindowHeight, LastFishX
	global TryScanned, TryFound, TryFishX, TryBarL, TryBarW, TryPrmReady
	global TryPrm1, TryPrm1I, TryPrm2, TryPrm2I, TryPrm3, TryPrm3I, TryPrmF, TryPrmFI, TryPrmT, TryPrmTI
	global TryhardBarColors, TryhardBarTol, TryhardFishColors, TryhardFishTol, TryhardTrackColors, TryXKey, TryXBuf, TryXNB, TryXNF
	if (TryScanned)
		return TryFound
	TryScanned := true
	TryFound := false
	TryFishX := -1
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return false
	if (!TryPrmReady)
		{
		PcSetPrm(TryPrm1, "0x33030B", 14, 0, 0)
		PcSetPrm(TryPrm1I, "0x33030B", 14, 0, 1)
		PcSetPrm(TryPrm2, "0x5F020A", 30, 0, 0)
		PcSetPrm(TryPrm2I, "0x5F020A", 30, 0, 1)
		PcSetPrm(TryPrm3, "0xBE0C0E", 66, 0, 0)
		PcSetPrm(TryPrm3I, "0xBE0C0E", 66, 0, 1)
		PcSetPrm(TryPrmF, "0x2F020C", 14, 0, 0)
		PcSetPrm(TryPrmFI, "0x2F020C", 14, 0, 1)
		PcSetPrm(TryPrmT, "0x3A0608", 14, 0, 0)
		PcSetPrm(TryPrmTI, "0x3A0608", 14, 0, 1)
		TryPrmReady := true
		}
	txKey := TryhardBarColors . "|" . TryhardBarTol . "|" . TryhardFishColors . "|" . TryhardFishTol . "|" . TryhardTrackColors
	if (txKey != TryXKey)
		{
		TryXKey := txKey
		txB := ColorListParse(TryhardBarColors)
		txF := ColorListParse(TryhardFishColors)
		txT := ColorListParse(TryhardTrackColors)
		TryXNB := (txB.n > 9) ? 9 : txB.n
		TryXNF := (txF.n > 9) ? 9 : txF.n
		VarSetCapacity(TryXBuf, 48 * (TryXNB + TryXNF + 1), 0)
		Loop, % TryXNB
			PcPrmAt(&TryXBuf + 48 * (A_Index - 1), txB.r[A_Index], txB.g[A_Index], txB.b[A_Index], RodCap(txB, A_Index, txT, RodTol(TryhardBarTol)), 0)
		Loop, % TryXNF
			PcPrmAt(&TryXBuf + 48 * (TryXNB + A_Index - 1), txF.r[A_Index], txF.g[A_Index], txF.b[A_Index], RodTol(TryhardFishTol), 0)
		}
	tfMaxW := Round(CaptureW * 0.02)
	tfNear := Round(CaptureW * 0.003) + 1
	tfC := []
	for tfI, tfO in [Round(WindowHeight * 0.0028), Round(WindowHeight * 0.0049), Round(WindowHeight * 0.0069)]
		{
		if (tfO < 1 or tfO > 17)
			continue
		tfR := []
		TryRowRuns(pCaptureBits - tfO * CaptureW * 4, TryPrmF, TryPrmFI, 1, tfR)
		Loop, % TryXNF
			TryRowRunsAt(pCaptureBits - tfO * CaptureW * 4, &TryXBuf + 48 * (TryXNB + A_Index - 1), 1, tfR)
		if (TryXNF)
			TryRunsMerge(tfR, 1)
		for tfK, tfV in tfR
			{
			if (tfV[2] - tfV[1] + 1 >= 3 and tfV[2] - tfV[1] + 1 <= tfMaxW)
				tfC.Push([(tfV[1] + tfV[2]) / 2, tfI])
			}
		}
	if (TryXNF)
		{
		tvK := Round(CaptureW * 0.012) + 2
		tvC := []
		for tfK, tfV in tfC
			{
			if (TryFishLineAt(Round(tfV[1]), tvK))
				tvC.Push(tfV)
			}
		tfC := tvC
		}
	tfBest := -1
	tfBestD := 999999
	for tfK, tfV in tfC
		{
		tfSeen := 1 << tfV[2]
		for tfK2, tfV2 in tfC
			{
			if (Abs(tfV2[1] - tfV[1]) <= tfNear)
				tfSeen := tfSeen | (1 << tfV2[2])
			}
		if (((tfSeen >> 1) & 1) + ((tfSeen >> 2) & 1) + ((tfSeen >> 3) & 1) >= 2)
			{
			tfD := (LastFishX >= 0) ? Abs(FishBarLeft + tfV[1] - LastFishX) : Abs(tfV[1] - CaptureW / 2)
			if (tfD < tfBestD)
				{
				tfBestD := tfD
				tfBest := tfV[1]
				}
			}
		}
	if (tfBest >= 0)
		{
		TryFishX := FishBarLeft + tfBest
		LastFishX := TryFishX
		}
	tbGap := Round(CaptureW * 0.006)
	tbMinW := Round(CaptureW * 0.02)
	if (tbMinW < 12)
		tbMinW := 12
	tbLs := []
	tbRs := []
	for tbI, tbY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tbP := pCaptureBits + tbY * CaptureW * 4
		tbR := []
		TryRowRuns(tbP, TryPrm1, TryPrm1I, 0, tbR)
		TryRowRuns(tbP, TryPrm2, TryPrm2I, 0, tbR)
		TryRowRuns(tbP, TryPrm3, TryPrm3I, 0, tbR)
		Loop, % TryXNB
			TryRowRunsAt(tbP, &TryXBuf + 48 * (A_Index - 1), 0, tbR)
		tbJ := 2
		while (tbJ <= tbR.Length())
			{
			tbV := tbR[tbJ]
			tbK := tbJ - 1
			while (tbK >= 1 and tbR[tbK][1] > tbV[1])
				{
				tbR[tbK + 1] := tbR[tbK]
				tbK--
				}
			tbR[tbK + 1] := tbV
			tbJ++
			}
		tbA := -1
		tbB := -1
		tbS := -1
		tbE := -1
		for tbK, tbV in tbR
			{
			if (tbS >= 0 and (tbV[1] - tbE - 1 <= tbGap or TryGapBright(tbP, tbE + 1, tbV[1] - 1)))
				{
				if (tbV[2] > tbE)
					tbE := tbV[2]
				}
			else
				{
				if (tbS >= 0 and tbE - tbS > tbB - tbA)
					{
					tbA := tbS
					tbB := tbE
					}
				tbS := tbV[1]
				tbE := tbV[2]
				}
			}
		if (tbS >= 0 and tbE - tbS > tbB - tbA)
			{
			tbA := tbS
			tbB := tbE
			}
		if (tbA >= 0 and tbB - tbA + 1 >= tbMinW and tbB - tbA + 1 <= CaptureW * 0.6)
			{
			tbLs.Push(tbA)
			tbRs.Push(tbB)
			}
		}
	if (tbLs.Length() < 2)
		return false
	tbA := (tbLs.Length() = 3) ? MedianOf(tbLs) : ((tbLs[1] > tbLs[2]) ? tbLs[1] : tbLs[2])
	tbB := (tbRs.Length() = 3) ? MedianOf(tbRs) : ((tbRs[1] < tbRs[2]) ? tbRs[1] : tbRs[2])
	tbO := Round(CaptureW * 0.006) + 2
	tbTL := TryTrackAtX(tbA - tbO)
	tbTR := TryTrackAtX(tbB + tbO)
	if (!(tbTL or tbA - tbO < 0) or !(tbTR or tbB + tbO >= CaptureW) or !(tbTL or tbTR))
		return false
	if (tfBest >= 0)
		{
		tbP := pCaptureBits + Floor(CaptureH * 0.50) * CaptureW * 4
		tbSum := 0
		Loop, 8
			tbSum += (NumGet(tbP + Round(tbA + (tbB - tbA) * (A_Index + 1) / 10) * 4, 0, "UInt") >> 16) & 0xFF
		if (tbSum <= 8 * 90)
			{
			tbPh := Round(CaptureW * 0.006)
			if (tfBest >= tbA - tbPh and tfBest <= tbA + tbPh + 2)
				tbA := Round(tfBest + tbPh + 1)
			else if (tfBest >= tbB - tbPh - 2 and tfBest <= tbB + tbPh)
				tbB := Round(tfBest - tbPh - 1)
			}
		}
	if (tbB - tbA + 1 < tbMinW)
		return false
	if (tfBest < 0)
		{
		tqC := []
		for tqI, tqY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			tqP := pCaptureBits + tqY * CaptureW * 4
			tqSum := 0
			tqN := 0
			tqX := tbA + 2
			while (tqX <= tbB - 2)
				{
				tqPx := NumGet(tqP + tqX * 4, 0, "UInt")
				tqR := (tqPx >> 16) & 0xFF
				if (tqR > ((tqPx >> 8) & 0xFF) + 60 and tqR > (tqPx & 0xFF) + 60)
					{
					tqSum += tqR
					tqN++
					}
				tqX++
				}
			if (tqN < 8)
				continue
			tqRef := tqSum / tqN
			if (tqRef < 110)
				continue
			tqS := -1
			tqX := tbA + 2
			while (tqX <= tbB - 1)
				{
				tqPx := (tqX <= tbB - 2) ? NumGet(tqP + tqX * 4, 0, "UInt") : 0xFFFFFF
				tqR := (tqPx >> 16) & 0xFF
				tqD := (tqR < tqRef * 0.72 and ((tqPx >> 8) & 0xFF) < 40 and (tqPx & 0xFF) < 40)
				if (tqD and tqS < 0)
					tqS := tqX
				else if (!tqD and tqS >= 0)
					{
					if (tqX - tqS >= 3 and tqX - tqS <= tfMaxW)
						tqC.Push([(tqS + tqX - 1) / 2, tqI, (tqS <= tbA + 2 or tqX >= tbB - 1) ? 100000 : 0])
					tqS := -1
					}
				tqX++
				}
			}
		tqBestD := 999999
		for tqK, tqV in tqC
			{
			tqSeen := 1 << tqV[2]
			for tqK2, tqV2 in tqC
				{
				if (Abs(tqV2[1] - tqV[1]) <= tfNear)
					tqSeen := tqSeen | (1 << tqV2[2])
				}
			if (((tqSeen >> 1) & 1) + ((tqSeen >> 2) & 1) + ((tqSeen >> 3) & 1) >= 2)
				{
				tqD := (LastFishX >= 0) ? Abs(FishBarLeft + tqV[1] - LastFishX) + tqV[3] : Abs(tqV[1] - (tbA + tbB) / 2) + tqV[3]
				if (tqD < tqBestD)
					{
					tqBestD := tqD
					tfBest := tqV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	if (tfBest < 0)
		{
		ttC := []
		ttK := Round(CaptureW * 0.003) + 2
		for ttI, ttY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			ttP := pCaptureBits + ttY * CaptureW * 4
			ttR := []
			TryRowRuns(ttP, TryPrmT, TryPrmTI, 1, ttR)
			for ttJ, ttV in ttR
				{
				if (ttV[2] - ttV[1] + 1 < 2 or ttV[2] - ttV[1] + 1 > tfMaxW)
					continue
				if (ttV[2] >= tbA - tbO and ttV[1] <= tbB + tbO)
					continue
				if (ttV[1] - ttK < 0 or ttV[2] + ttK >= CaptureW)
					continue
				if (TryTrackPx(NumGet(ttP + (ttV[1] - ttK) * 4, 0, "UInt")) and TryTrackPx(NumGet(ttP + (ttV[2] + ttK) * 4, 0, "UInt")))
					ttC.Push([(ttV[1] + ttV[2]) / 2, ttI])
				}
			}
		ttBestD := 999999
		for ttJ, ttV in ttC
			{
			ttSeen := 1 << ttV[2]
			for ttJ2, ttV2 in ttC
				{
				if (Abs(ttV2[1] - ttV[1]) <= tfNear)
					ttSeen := ttSeen | (1 << ttV2[2])
				}
			if (((ttSeen >> 1) & 1) + ((ttSeen >> 2) & 1) + ((ttSeen >> 3) & 1) >= 2)
				{
				ttD := (LastFishX >= 0) ? Abs(FishBarLeft + ttV[1] - LastFishX) : Abs(ttV[1] - (tbA + tbB) / 2)
				if (ttD < ttBestD)
					{
					ttBestD := ttD
					tfBest := ttV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	TryBarL := FishBarLeft + tbA
	TryBarW := tbB - tbA + 1
	TryFound := true
	return true
}

; -------------------------------------------------- Stellarwave Melody

SwLog(m) {
}

SwSetup() {
	global SwReady, SwPrmFr, SwPrmFrI, SwPrmBk, SwPrmBkI, SwPrmCap, SwPrmCapI, SwPrmWh, SwPrmWhI, SwPrmCore, SwPrmCoreI, SwPrmStU, SwPrmStUI
	global SwPrmHd, SwPrmHdI, SwFrTol, SwColKey, SwXBarN, SwXCapN, SwXHdN, SwTplF, SwTplFBuf
	global SwZ, SwFrR, SwFrG, SwFrB, SwTpl, SwGradDef, SwWSign, SwStarV, SwStarT, SwLockFail, SwLockN, SwPitchRef, SwPitchRefH, SwStarYRef, SwStarYRefH
	global SwCacheW, SwCacheH, SwCacheSB, SwCacheFrH, SwCacheFrT
	SwTplHex := ""
	SwTplHex .= "E9E3E2EDECBB6C0F0000051497EBE3D6C6BAB9B7C9F0CD8315000EB1EDC3B8C0C3ECF3E5C0BBEEC5762F91E9BAC5EFFDDFE0AABAEEC2C0F6B3ACEDC0C0F0C1B7E9BA63177BEFBAD3F6F2D6BBF3B77020E2BC4B0008AFD9B9F8F7B9D9D3870900CCCF54000031EBB8D8DBB9F4A1380B3AC6D54C000001C0CCBDBDCCE28D455C5CD1800D00000073E0B7B7E4C166455C5C09020000000036EDB7B7F1A62E01174500000000000016EFB8BAF59C1D06030000000000000005E9BAC4E993020B070400000000000000DDC4CDDE87060F0D0A00000403000000C9C8D4D6720A12100D00000505020000C5C4D5D07207131412000407070703009AD0E0C65F09141212"
	SwTplHex .= "007F4642720300000000000DA361265900595B169E33010000000444C5414534001A8F18569C47140C195BD667287606000064693257B2BEB5D5D7823C563600000008AA883C3148665945436A740200000006AAA448314E615E514064A0130000002D933A48ADB2949FB588365B76010005742540A853120B0D2D78622A822F002068159F4E06000000032D6F4C3079004A3E389C1900000000001051651F9500533F5591060000000000084B661F9F004F413AA01800000000000B50682095002D6211A1480200000001276D4E387B0006711F4CA54F0A0506287F602D802F00002C7E3B4EB1A78FA6BC8E3C55750300000155A74A33507A695543657C0F00"
	SwTplHex .= "C9B07E5F43493B3F4144648BB3D2C4378AC3BFB7B5B8B1B0C7C5C1BFC090763A04246BC6CFA3A7B9A5B5CA7A344A321B01020E85E03C4245438CEE40351F090600010773DE2A3B0E0363EE40330D05040001066FDD2835030050EE41320B040300010672DE2A3004014FEE41320B040400010580DD282F05024FEF42320A050500010584DD292D040253F04B320A050600010580DD2A2F040255F159300A060600010575DE2A2F050259F05A2E08060600010576DE2A36090367F15B2F09050600020586DF2F3C342D93EF5B300E0605020835BADC85949C96A8D866342B0F0957A9BBC3B8B7B9BBBDBDC1B387624326D8BBB49B858A7178818FB5C3D3C8B449"
	SwTplHex .= "083084B4977155504D4B4B4B5069767C60B58E554A7091A8ABACAFA7926D2D86B2644F4DB2B77D3A322C2E4669A7A55B5A514F494CA84F0A0100000513717B3A6497BCAF613B8A0F0100002F939C8E838D392F76C9447725020034C67554494A68130A11D0705844060ECA6D4C93BCC061160C24D46C59430852BD32914D1F479A543D9FCB407C24078187407D08040860A4C2B05D3A750D017F8D3B8F14040E68534E444B8519040045C2398571386D8498988D5C140601000BC1794F87B4AE0D2029130C0A0301000164DD8E644B47096096754C3721182055A5D6D07E44440CC2646F87A2C0C4C8BF9E7C564471980796856C544D4C4C4A4744627C8E541C"
	SwTplHex .= "0000000007489A75899883494F0E010000000000249670ACC8C6CDAD3454010001010008637C8A7D260B43DC63550C000101000B8E73813C0401029E8C4E280001020202AD6B872102010089895C2C0002020209C46E782B020103B26B6921000202075CBE795355080028C05F7702000116829E7C7641712F1CAE797042000002689579B9C7953D87B2AB60790800000AA6689C989FD95A89C7648B2300000014B950878594D35DB48971610000000000A6705C94A7B456B65D8521010000000041BE7E7E8E6497A54B620D04010100000153AAA099A1C98C5658100870312F0000010F2E2F33A39F3E77435EC738480000000203020339C6596BA1AA7A5631"
	SwTplHex .= "9E93A8B07E6864857B625D757595624485AD9A967B8C7567648C7A5D86C19A385B95AB8FB39E955C94B49C51BAD2AE26587DB396A3919655A48C9B66A1C0B33A567BB39E807BA14F8B5793788DBBB654557AB39D6E6EA75A875098798CBCB8545679B4986C6EA660854BA0798CC5B02E557DB4966570A2597E48AC788FC8AE2E567EB4965F6E9B567A49AF7891CDA734567FB5965E6B9D57774AB17899CB983D5682B4975A77A15A694BB0789BC079425783B4905668A1586451B07987A55340587FB48B514AA458614BAF7F6E9C3D2D577BA691422790846032B38C6E72541E29444818100F1F271666A4906F876A2603030201030104071FA47957789B962F"
	SwTplHex .= "0000000C70A69C917B74666F4808000000001EAD987A6C7F83937E604C680C00000EB1854B606B473F54A0B06B3D670201709A3C6D3301000102095EC14F5B3503BD584D45000000000000029996315E20B5416E0F000000000000004BB8286720B4406B100000000000000041B92A6A05C252533900000000000001819B2F6A31BE8B2F7503000000000012BD5D5677869CAA6240320000000003898F4C7C837A7B7B7B24410000000003B57C7C7B7B7678787753150000000100528186888A0101010100000000000200000414181C010101000100000001020101000000006769686767666563625550504E4C4C4E7D7B7C7D7D7D7D7D7D7D7D7C7C7E7D7C"
	SwTplHex .= "A59EB4A09F9DB79D9934450F00000000D5A362A1E0A77081E47E343300000000B6B62798DDBC326FD3C71C5200000000A2A32688D3C52468BCDE1F5007000000A19C2A6DBCC523659CE8314F0E000000A29B3568BBC5236591E9394D0E000000A39B3763C1C5246496E8394E0E000000A49B365FBFC72463A6E1264E0E000000A49C365CBDD324639DDA1F4E0C000000A49C365ABBD424629ED9215009000000A39C3956B3D4255FACD921560B010000959D39478DD525569CD8214E32715A395C875827339D523F4DE56C596FE19E1B03121302020C150408C3C1949DA5A2530101010101010000001A9EB3B2AB967101010101000000000000022BA6DC8A2E"
	SwTplHex .= "0202010001010C1CB0B1B19C9C9C9E9E020201000101081179E7F0D5F2CCA79E02020101010002040E3A9FCCD6A6A2AE02020101010000000C1190D6B29CE8BB02020101010002070F5EECB59EBADABD030302010102090F57E7C6A2B793C7BD2C202A1C070D1359E7C2B3B68F78B6BF47C8DFA0784E84EAC1B1D4896E486CB972C7BFEABCC8EDBCAED8A56A231F356250DDBABFF2F3BBA9D8A67D1600010B1F3B95E8B9BBB8ACD8A8811E00000101023A5CECE2ACAAD8C98E5C0200000001023C8FECBCB4B2BCD4976E08010000010277E1BAB9EDEAB4BCC48C310101000101DDB9B9F0C7D8E6B3BBA5570301010101BBB8E8B08B76A3D4C48E2D0302010001"
	SwTplHex .= "8873535A6393ABA98F61371302000001B88E9889AEA592ADB37B681A0A000001BDBD9FC0AB8779558FA5642B1001000162B6BFBC8583372767B16339140201025684C0B28954221F5DAC663E160302035670C1A19422171B69A95E39150402035667B4A29214131A66AD603C160A06065660B49D7C12131B6EA36C471B2C261C565CAC9765100F1C6D97757682A49A714C4C67681C060E1C6CA789AC9E9CBAB80602010102010D1A66AEA2927F6A8FD70101010002010E1949B8A47876275AD2010101010204161B54AD976D6D4471D00101010B1E25254395A9A59F839CB5B400012353516578A2A26990A0A9A89F5D00005076A9ACB0996F6825243D4D432A"
	SwTplHex .= "000000000000010000000000000000004938110200040A090A080300010002059BA1903F1B202761543C1208043C8169C3C09D9B3D46A8ACA85C4F0F1DC3C3C49CC4C68E81ABA561B79F473E9FA58BC99486C6A1A3C86B5954C45D84C654438B706F9ACDB4955D2B1B7FB6A68C35191B6663678E704F371D15174E62441A090A9897917137282E4C5341160E0D387354C5C090913B46B6B3A650460F21B9C6C3A4CBC48867A7AD67B4944A3091B296D2958FC9A09BCF685A6CC44E84C6703F99736DA5C8B19E522B1AA4ADA49539182C1A4D64968356310F0F1663784F1D08050007274623100701010507090905010000000000000001000000000001000201"
	SwTplHex .= "28C35257470300000000000162B544810CB38934741F010000000029C46C51780324D2712E6A0501000003A48F448A2903036EB7376D1E0301003DC251735309030217DB663C520401029C92408B2007040420C6982584240826DD625D85250A1E6082C6AE3082968CA2DD566396835F9C9677786F686C75797B746B6E664C6B90A686897D5C718384898866688479871A4E7EBEB92A969B8D9DE55278A78446050413B79A2C8323072DDC615277150804030AD46F3858040003AC9036791305040342CC4C632B0200005EB943752C060505AE8F2C770A02000113CD7240640E0549C2524F3F03010001037FA942693414C376337409020302010119C879356F"
	SwGradHex := "EDDEACEADBADE8D7B1E6D2B3E3CBB7E3C8BBE1C3BDDFBEC0DDBAC3DBB4C5D8B0C8D6ACC9D1A5C9CFA0CBCB9BCBC997CCC693CEC18CCEBF89D0BC84D0B87DD2B77AD1B779CEB778CCB776C9B875C6B773C2B672C0B671BCB570B8B56FB5B46DB2B46CAFB36BACB36AA8B369A6B165A0AF639CAE6298AE6095AB5E90AB5D8DA95C8AA95A86A75982A6577EA55579A35377A25476A15375A054759F54759E55739C54729C54729B547099547097546E93536A9153698D52668A5265875262855360"
	SwZ := ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
	SwFrR := 85
	SwFrG := 68
	SwFrB := 109
	SwFrTol := 26
	SwSetFrame(SwFrR, SwFrG, SwFrB)
	PcSetPrm(SwPrmBk, "0x000000", 45, 0, 0)
	PcSetPrm(SwPrmBkI, "0x000000", 45, 0, 1)
	PcSetPrm(SwPrmCap, "0xAFDAE8", 22, 0, 0)
	PcSetPrm(SwPrmCapI, "0xAFDAE8", 22, 0, 1)
	PcSetPrm(SwPrmWh, "0xFFFFFF", 30, 0, 0)
	PcSetPrm(SwPrmWhI, "0xFFFFFF", 30, 0, 1)
	PcSetPrm(SwPrmHd, "0xFFFFFF", 30, 0, 0)
	PcSetPrm(SwPrmHdI, "0xFFFFFF", 30, 0, 1)
	PcSetPrm(SwPrmCore, "0x7E5CA6", 22, 0, 0)
	PcSetPrm(SwPrmCoreI, "0x7E5CA6", 22, 0, 1)
	PcSetPrm(SwPrmStU, "0x3C1C60", 30, 0, 0)
	PcSetPrm(SwPrmStUI, "0x3C1C60", 30, 0, 1)
	VarSetCapacity(SwTpl, 3072, 0)
	Loop 3072
		NumPut("0x" . SubStr(SwTplHex, 2 * A_Index - 1, 2), SwTpl, A_Index - 1, "UChar")
	SwTplF := []
	Loop 3072
		SwTplF.Push(NumGet(SwTpl, A_Index - 1, "UChar") / 255.0)
	VarSetCapacity(SwTplFBuf, 3072 * 8, 0)
	Loop 3072
		NumPut(SwTplF[A_Index], SwTplFBuf, (A_Index - 1) * 8, "Double")
	VarSetCapacity(SwGradDef, 192, 0)
	Loop 192
		NumPut("0x" . SubStr(SwGradHex, 2 * A_Index - 1, 2), SwGradDef, A_Index - 1, "UChar")
	SwWSign := 0
	SwStarV := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwStarT := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwLockFail := false
	SwLockN := 0
	SwColKey := ""
	SwXBarN := 0
	SwXCapN := 0
	SwXHdN := 0
	SwPitchRef := -1
	SwPitchRefH := -1
	SwStarYRef := -1
	SwStarYRefH := -1
	SwCacheW := -1
	SwCacheH := -1
	SwCacheSB := 0
	SwCacheFrH := -1
	SwCacheFrT := -1
	SwReady := true
}

SwSetFrame(r, g, b) {
	global SwPrmFr, SwPrmFrI, SwFrTol
	hex := Format("0x{:02X}{:02X}{:02X}", r, g, b)
	PcSetPrm(SwPrmFr, hex, SwFrTol, 0, 0)
	PcSetPrm(SwPrmFrI, hex, SwFrTol, 0, 1)
}

; the six Stellarwave color boxes as one string, and back
SwColsGet() {
	global StellarBarColors, StellarBarTol, StellarFishColors, StellarFishTol, StellarHeadColors, StellarHeadTol
	return StellarBarColors . "|" . StellarBarTol . "|" . StellarFishColors . "|" . StellarFishTol . "|" . StellarHeadColors . "|" . StellarHeadTol
}

SwColsSet(v) {
	global StellarBarColors, StellarBarTol, StellarFishColors, StellarFishTol, StellarHeadColors, StellarHeadTol
	p := StrSplit(v, "|")
	StellarBarColors := p[1], StellarBarTol := p[2], StellarFishColors := p[3], StellarFishTol := p[4], StellarHeadColors := p[5], StellarHeadTol := p[6]
}

SwTolOf(v, d) {
	if v is not number
		return d
	v := Round(v)
	if (v < 0)
		return 0
	if (v > 255)
		return 255
	return v
}

SwXFill(ByRef buf, o, tol) {
	n := o.n - 1
	if (n > 8)
		n := 8
	VarSetCapacity(buf, 48 * 8, 0)
	Loop % n
		PcPrmAt(&buf + (A_Index - 1) * 48, o.r[A_Index + 1], o.g[A_Index + 1], o.b[A_Index + 1], tol, 0)
	return (n > 0) ? n : 0
}

SwApplyColours() {
	global StellarBarColors, StellarBarTol, StellarFishColors, StellarFishTol, StellarHeadColors, StellarHeadTol
	global SwColKey, SwFrR, SwFrG, SwFrB, SwFrTol, SwFrLearned, SwPrmCap, SwPrmCapI, SwPrmHd, SwPrmHdI
	global SwXBar, SwXBarN, SwXCap, SwXCapN, SwXHd, SwXHdN
	key := StellarBarColors . "|" . StellarBarTol . "|" . StellarFishColors . "|" . StellarFishTol . "|" . StellarHeadColors . "|" . StellarHeadTol
	if (key == SwColKey)
		return
	SwColKey := key
	bt := SwTolOf(StellarBarTol, 26)
	ft := SwTolOf(StellarFishTol, 22)
	ht := SwTolOf(StellarHeadTol, 30)
	o := ColorListParse(ColCount(StellarBarColors) ? StellarBarColors : "0x55446D")
	SwFrR := o.r[1]
	SwFrG := o.g[1]
	SwFrB := o.b[1]
	SwFrTol := bt
	SwSetFrame(SwFrR, SwFrG, SwFrB)
	SwFrLearned := false
	SwXBarN := SwXFill(SwXBar, o, bt)
	o := ColorListParse(ColCount(StellarFishColors) ? StellarFishColors : "0xAFDAE8")
	hex := Format("0x{:02X}{:02X}{:02X}", o.r[1], o.g[1], o.b[1])
	PcSetPrm(SwPrmCap, hex, ft, 0, 0)
	PcSetPrm(SwPrmCapI, hex, ft, 0, 1)
	SwXCapN := SwXFill(SwXCap, o, ft)
	o := ColorListParse(ColCount(StellarHeadColors) ? StellarHeadColors : "0xFFFFFF")
	hex := Format("0x{:02X}{:02X}{:02X}", o.r[1], o.g[1], o.b[1])
	PcSetPrm(SwPrmHd, hex, ht, 0, 0)
	PcSetPrm(SwPrmHdI, hex, ht, 0, 1)
	SwXHdN := SwXFill(SwXHd, o, ht)
	SwLog("colours bar " . SwFrR . "," . SwFrG . "," . SwFrB . "+" . SwXBarN . " tol " . bt . "  fish +" . SwXCapN . " tol " . ft . "  head +" . SwXHdN . " tol " . ht)
}

SwRunsAt(p, x0, x1, a, gap, rr) {
	x := x0
	s0 := -1
	e0 := -1
	n := 0
	while (x <= x1 and n < 60)
		{
		i := PcFindAt(p + x * 4, x1 - x + 1, 4, a)
		if (i < 0)
			break
		s := x + i
		j := PcFindAt(p + (s + 1) * 4, x1 - s, 4, a + 24)
		e := (j < 0) ? x1 : s + j
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

SwRunsX(p, x0, x1, a, n, gap, rr) {
	Loop % n
		SwRunsAt(p, x0, x1, a + (A_Index - 1) * 48, gap, rr)
	TryRunsMerge(rr, gap)
}

SwColScan(x, y0, y1, need, span, aN, aI) {
	global pCaptureBits, CaptureW
	y := y0
	while (y <= y1 - need)
		{
		i2 := PcFindAt(pCaptureBits + (y * CaptureW + x) * 4, y1 - y + 1, CaptureW * 4, aN)
		if (i2 < 0)
			break
		y := y + i2
		j := PcFindAt(pCaptureBits + ((y + 1) * CaptureW + x) * 4, y1 - y, CaptureW * 4, aI)
		ln := (j < 0) ? (y1 - y + 1) : (j + 1)
		if (ln >= need)
			{
			yb := y + ln
			k2 := 0
			while (k2 < span and yb + k2 <= y1)
				{
				if (SwLum(pCaptureBits + ((yb + k2) * CaptureW + x) * 4) >= 240)
					return y
				k2++
				}
			}
		y := y + ln
		}
	return -1
}

SwNow() {
	global QpcFreq
	DllCall("QueryPerformanceCounter", "Int64*", t)
	return t / QpcFreq
}

SwLum(p) {
	px := NumGet(p + 0, 0, "UInt")
	return ((px >> 16) & 0xFF) + 2 * ((px >> 8) & 0xFF) + (px & 0xFF)
}

SwMedian(arr) {
	n := arr.Length()
	if (n < 1)
		return 0
	a := []
	for i, v in arr
		a.Push(v)
	j := 2
	while (j <= n)
		{
		v := a[j]
		k := j - 1
		while (k >= 1 and a[k] > v)
			{
			a[k + 1] := a[k]
			k--
			}
		a[k + 1] := v
		j++
		}
	return (Mod(n, 2) = 1) ? a[(n + 1) // 2] : (a[n // 2] + a[n // 2 + 1]) / 2
}

SwRuns(p, x0, x1, ByRef prm, ByRef prmI, gap, rr) {
	x := x0
	s0 := -1
	e0 := -1
	n := 0
	while (x <= x1 and n < 60)
		{
		i := PcFind(p + x * 4, x1 - x + 1, 4, prm)
		if (i < 0)
			break
		s := x + i
		j := PcFind(p + (s + 1) * 4, x1 - s, 4, prmI)
		e := (j < 0) ? x1 : s + j
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

SwCover(rr, a, b) {
	t := 0
	for i, v in rr
		{
		lo := (v[1] > a) ? v[1] : a
		hi := (v[2] < b) ? v[2] : b
		if (hi >= lo)
			t += hi - lo + 1
		}
	return t
}

SwGlowAdd(x, now) {
	global SwGlowX, SwGlowT
	if (!IsObject(SwGlowX))
		{
		SwGlowX := []
		SwGlowT := []
		}
	SwGlowX.Push(x)
	SwGlowT.Push(now)
	while (SwGlowX.Length() > 8)
		{
		SwGlowX.RemoveAt(1)
		SwGlowT.RemoveAt(1)
		}
}

SwGlowZones(now) {
	global SwGlowX, SwGlowT, SwZL, SwZH, SwPitch
	SwZL := []
	SwZH := []
	if (!IsObject(SwGlowX))
		return 0
	lo := []
	hi := []
	Loop % SwGlowX.Length()
		{
		a := now - SwGlowT[A_Index]
		h := (a < 0.55) ? 1.4 : ((a < 0.7) ? 1.0 : ((a < 0.85) ? 0.5 : 0))
		if (a < 0 or h <= 0)
			continue
		r := Round(h * SwPitch)
		l := SwGlowX[A_Index] - r
		j := lo.Length() + 1
		while (j > 1 and lo[j - 1] > l)
			j--
		lo.InsertAt(j, l)
		hi.InsertAt(j, SwGlowX[A_Index] + r)
		}
	Loop % lo.Length()
		{
		n := SwZL.Length()
		if (n and lo[A_Index] <= SwZH[n] + 1)
			{
			if (hi[A_Index] > SwZH[n])
				SwZH[n] := hi[A_Index]
			}
		else
			{
			SwZL.Push(lo[A_Index])
			SwZH.Push(hi[A_Index])
			}
		}
	return SwZL.Length()
}

SwGlowNear(x, h, amax, now) {
	global SwGlowX, SwGlowT, SwPitch
	if (!IsObject(SwGlowX))
		return false
	Loop % SwGlowX.Length()
		{
		a := now - SwGlowT[A_Index]
		if (a >= 0 and a < amax and Abs(SwGlowX[A_Index] - x) <= h * SwPitch)
			return true
		}
	return false
}

SwCoverX(rr, a, b) {
	global SwZL, SwZH
	c := SwCover(rr, a, b)
	Loop % SwZL.Length()
		{
		l := (SwZL[A_Index] > a) ? SwZL[A_Index] : a
		h := (SwZH[A_Index] < b) ? SwZH[A_Index] : b
		if (h >= l)
			c := c - SwCover(rr, l, h)
		}
	return c
}

SwZoneLen(a, b) {
	global SwZL, SwZH
	n := 0
	Loop % SwZL.Length()
		{
		l := (SwZL[A_Index] > a) ? SwZL[A_Index] : a
		h := (SwZH[A_Index] < b) ? SwZH[A_Index] : b
		if (h >= l)
			n := n + h - l + 1
		}
	return n
}

SwInZone(x, m) {
	global SwZL, SwZH
	Loop % SwZL.Length()
		{
		if (x >= SwZL[A_Index] - m and x <= SwZH[A_Index] + m)
			return true
		}
	return false
}

SwFightReset() {
	global SwPreK, SwParkAt, SwFrStillRef, SwFrStillT, SwFrameT, SwReactEst, SwFoundT, SwBarHold, SwGlowX, SwGlowT, SwZL, SwZH, SwFishHeld
	global SwPressK, SwPressQ, SwPressMs, SwPressDecT, SwPressNom, SwPressCx, SwPressCy, SwPressPre, SwPressSx, SwPressSy, SwWantK, SwWantT, SwWantNom, SwWantPre, SwWantSx, SwWantSy, SwWantCx, SwWantCy
	global SwLitFastT, SwLitFastV, SwHov1, SwHov2, SwMoveOn, SwHyb, SwWantStrk, SwPressLit, SwLitRawN
	global SwMaxSigns, SwLockStrk, SwLockT
	static tp := false
	if (!tp)
		{
		DllCall("winmm\timeBeginPeriod", "UInt", 1)
		tp := true
		}
	SwMemReset()
	global SwReady, SwS, SwSB, SwSX, SwPitch, SwSlotC0, SwFrTop, SwFrMiss, SwLastC, SwLastL, SwW, SwWSign, SwWRing, SwFound, SwBarL, SwBarW, SwFishX, SwFrRef, SwFrRefT, SwFrMoveT
	global SwFishAt, SwFishLast, SwPhase, SwPhaseT, SwInvalidT, SwUndarkT, SwStarsValid, SwLit, SwLitPrev, SwLitRaw, SwLitRawT, SwStarFound, SwStarY, SwStarX0, SwStarPitch, SwStarRetryT, SwStarOkT
	global SwGradOk, SwGrad, SwDarkR, SwDarkG, SwDarkB, SwFrLearned, SwLastStep, SwPiano, SwPianoDis, SwTipT, SwScanned, SwStarStableT, SwStarPitch, SwStarX0, SwLockFail, SwLockN
	global WindowWidth, WindowHeight, FishBarTop, FishBarLeft, RobloxHwnd, MacroRunning, LookDownX, LookDownY, SwWMeas, SwMeasN, SwMeasT, SwPostT
	global SwSM, SwSB, SwFrH, SwFrHC, SwFrT, SwFrTC, SwFrHT, SwFrBad, SwFrOk, SwStarFullT, SwCacheW, SwCacheH, SwCacheSB, SwCacheFrH, SwCacheFrT
	if (!SwReady)
		SwSetup()
	SwApplyColours()
	SwWMeas := false
	SwMeasN := 0
	SwMeasT := 0
	SwPostT := 0
	SwS := WindowHeight / 1440.0
	SwSX := WindowWidth / 2560.0
	SwSM := (SwS < SwSX) ? SwS : SwSX
	SwSB := SwSM
	SwFrH := -1
	SwFrHC := -1
	SwFrT := -1
	SwFrTC := -1
	SwFrHT := 0
	SwFrBad := 0
	SwFrOk := false
	SwStarFullT := 0
	if (SwCacheH = WindowHeight and SwCacheW = WindowWidth)
		{
		SwSB := SwCacheSB
		SwFrH := SwCacheFrH
		SwFrT := SwCacheFrT
		SwFrOk := true
		}
	SwPitch := 115.5 * SwSX
	SwSlotC0 := WindowWidth / 2 - 5.5 * SwPitch
	SwFrTop := Round(1208 * SwS) - Round(FishBarTop)
	SwFrMiss := 0
	SwFrRef := -1
	SwFrRefT := 0
	SwFrMoveT := 0
	SwFrStillRef := -1
	SwFrStillT := 0
	SwLastC := -1
	SwLastL := -1
	SwW := Round(WindowHeight * 0.625)
	SwWRing := []
	SwFound := false
	SwBarL := -1
	SwBarW := 0
	SwFishX := -1
	SwFishAt := 0
	SwFishLast := -1
	SwPhase := 0
	SwPhaseT := 0
	SwInvalidT := 0
	SwUndarkT := 0
	SwStarsValid := false
	SwLit := 0
	SwLitPrev := 0
	SwLitRaw := -1
	SwLitRawT := 0
	SwStarFound := false
	SwStarRetryT := 0
	SwStarOkT := 0
	SwStarStableT := 0
	SwStarPitch := 0
	SwStarX0 := 0
	SwGradOk := false
	VarSetCapacity(SwGrad, 192, 0)
	SwDarkR := 22
	SwDarkG := 8
	SwDarkB := 22
	SwFrLearned := false
	SwLastStep := 0
	SwPiano := -1
	SwPianoDis := 0
	SwTipT := 0
	SwScanned := false
	; every fight gets a fresh try - a locked cursor in an earlier fight does not switch sign clicking off for good
	SwLockFail := false
	SwLockStrk := 0
	SwLockT := 0
	SwFrameT := 0
	SwReactEst := 0.12
	SwFoundT := 0
	SwBarHold := false
	SwGlowX := []
	SwGlowT := []
	SwZL := []
	SwZH := []
	SwFishHeld := false
	SwPreK := 0
	SwParkAt := 0
	SwPressK := 0
	SwPressQ := 0
	SwPressMs := 90
	SwPressDecT := 0
	SwPressNom := 0
	SwPressCx := 0
	SwPressCy := 0
	SwPressPre := false
	SwPressSx := 0
	SwPressSy := 0
	SwWantK := 0
	SwWantT := 0
	SwWantNom := 0
	SwWantPre := false
	SwWantSx := 0
	SwWantSy := 0
	SwWantCx := 0
	SwWantCy := 0
	SwLitFastT := 0
	SwLitFastV := 0
	SwWantStrk := 0
	SwPressLit := 0
	SwLitRawN := 0
	SwHov1 := 0.025
	SwHov2 := 0.03
	SwMoveOn := 0.06
	SwHyb := 0.012
	SwPhaseReset()
	OjReset()
	; (passive mode waiting for a minigame leaves the mouse where you put it)
	if (MacroRunning and RobloxHwnd and WinActive("ahk_id " . RobloxHwnd) and !PasIdle())
		MouseMove, %LookDownX%, %LookDownY%, 0
}

; passive mode, waiting for a minigame (not in one): the mouse is left alone and Roblox may be in the background
PasIdle() {
	global MacroRunning, PassiveAll, SwPassive, SpecialRod, MgInPlay
	return (MacroRunning and !MgInPlay and (PassiveAll or (SwPassive and SpecialRod = "Stellarwave Melody")))
}

; true when the fish bar area on screen really shows Roblox (in front, or not covered by another window)
PasRobloxShown() {
	global RobloxHwnd, FishBarLeft, FishBarRight, FishBarTop, FishBarBottom
	if (!RobloxHwnd)
		return false
	if (WinActive("ahk_id " . RobloxHwnd))
		return true
	me := DllCall("GetCurrentProcessId")
	for i, f in [0.1, 0.5, 0.9]
		{
		VarSetCapacity(pt, 8, 0)
		NumPut(Round(FishBarLeft + f * (FishBarRight - FishBarLeft)), pt, 0, "Int")
		NumPut(Round((FishBarTop + FishBarBottom) / 2), pt, 4, "Int")
		DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
		if (A_PtrSize = 8)
			h := DllCall("WindowFromPoint", "Int64", NumGet(pt, 0, "Int64"), "Ptr")
		else
			h := DllCall("WindowFromPoint", "Int", NumGet(pt, 0, "Int"), "Int", NumGet(pt, 4, "Int"), "Ptr")
		r := DllCall("GetAncestor", "Ptr", h, "UInt", 2, "Ptr")
		if (r = RobloxHwnd)
			continue
		; our own overlays (info panel, HUD) do not count as covering it
		DllCall("GetWindowThreadProcessId", "Ptr", r, "UInt*", wpid)
		if (wpid != me)
			return false
		}
	return true
}

SwPhaseReset() {
	global SwVetoM, SwVetoZ, SwRecZ, SwDwell, SwDwellPN, SwPressN, SwClickStall, SwPress0At, SwUnsureK, SwUnsureT, SwUnsureR
	global SwSlotSt, SwSlotFirst, SwSlotHits, SwSlotLvl, SwSlotGone, SwOrder, SwK0, SwClicks, SwClickAt, SwClickLit, SwClickSlot, SwRetry, SwSlotBlind
	global SwStop, SwStopWhy, SwLastClick, SwTie, SwLastOnset, SwGradOk, SwPurpleN, SwClickTook, SwTieWas, SwWantK, SwWantStrk
	global SwOverK, SwOverT, SwOverL, SwOverR, SwOverS, SwTryAt
	global SwSlotSt, SwSlotFirst, SwSlotHits, SwSlotLvl, SwSlotGone, SwOrder, SwK0, SwClicks, SwClickAt, SwClickLit, SwClickSlot, SwRetry, SwFailN, SwFailAt, SwRetryK, SwGuessTried, SwGuessDone, SwMem
	global SwStop, SwStopWhy, SwLastClick, SwTie, SwLastOnset, SwGradOk, SwPurpleN, SwClickTook, SwTieWas
	global SwAllN, SwAllT, SwAllI
	SwPreEnd("reset")
	SwAllN := 0
	SwAllI := 0
	SwDwell := false
	SwWantK := 0
	SwWantStrk := 0
	SwSlotSt := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	if (!IsObject(SwMem))
		SwMemReset()
	Loop 12
		{
		if (SwMem[A_Index])
			SwSlotSt[A_Index] := 3
		}
	SwSlotFirst := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotHits := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotLvl := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotGone := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotBlind := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwTie := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwTieWas := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwVetoM := 0
	SwVetoZ := -1
	SwRecZ := -1
	SwOrder := []
	SwK0 := -1
	SwClicks := 0
	SwClickAt := 0
	SwClickLit := 0
	SwClickSlot := 0
	SwRetry := 0
	SwFailN := 0
	SwFailAt := 0
	SwRetryK := 0
	SwPurpleN := 0
	SwClickTook := 0
	SwDwellPN := 0
	SwPressN := 0
	SwClickStall := 0
	SwPress0At := 0
	SwUnsureK := 0
	SwUnsureT := 0
	SwUnsureR := 0
	SwOverK := 0
	SwOverT := 0
	SwOverL := 0
	SwOverR := -1
	SwOverS := 0
	SwTryAt := 0
	SwStop := false
	SwStopWhy := ""
	SwLastClick := 0
	SwLastOnset := 0
	SwGradOk := false
}

SwSlotX(k) {
	global SwSlotC0, SwPitch
	return SwSlotC0 + (k - 1) * SwPitch
}

;---- Ominous Ouija (a Stellarwave preset) ------------------------------------------------------------
; The same game as the zodiac signs: 12 stars, and tokens that show up one by one in 12 spots on the bar and are
; clicked in star order - here each token shows a letter and the order spells GRIMPLANCHET. Now and then the
; tokens left move to new spots, so a spot that empties is forgotten and read again. Built and checked on 4K
; recordings of real fights; every size is in star spacings (sp), so it works at any window size.

OjReset() {
	global OjCache, OjPend, OjMiss, OjClickAt, OjClickLit, OjClickK, OjTry, OjStarsVis, OjStarSeenT, OjNextRd, OjStarsMissN, OjLastFind, OjBarL, OjTipT
	OjCache := {}, OjPend := {}, OjMiss := {}
	OjClickAt := 0, OjClickLit := -1, OjClickK := 0, OjTry := 0
	OjStarsVis := false, OjStarSeenT := 0, OjNextRd := 1, OjStarsMissN := 0
	; a blank time would make "now - OjLastFind < 300" true forever (blank math is blank in AHK v1) - so set it
	OjLastFind := -99999, OjBarL := -99999, OjTipT := 0
}

; the 12 letters as 10x14 coverage grids (from a 4K fight): letter:aspect*1000:140 hex bytes
OjTplInit() {
	global OjTpl
	if (IsObject(OjTpl))
		return
	OjTpl := {}
	for i, part in StrSplit("G:757:000067FAFFFFE0C656000081D7FA4E3479D7B5002BE9D78100000067E900C6E0FF2B000000098100C6CFC600000000000000B5D7AC000079B52B6792ACD7AC000045FAD7FFBEE9E0E000000081A4FF22AC9BD71100005681FF005FC6D75F00005F81FF0000E0FFFF6767FF9BFF00000967F1D7FFC6BEFF00000000092B220000000000092B2B2B342B2B0000|R:875:CDFC5ECDFFFFDC180000A5ECECFFADCDFFB5000027C5ECB50010D4EC2F00279DEC7600009DEC5700279DEC760008E4EC5E00279DEC76007EFFEC1F00279DECFCDCECFF6600002FBDFFEC8EFFFF270000279DEC7600A5D4A50000279DEC76004FBDEC1F473FDCECCD1008BDE4BDE4F4ECD4FF7600B5D4ECB59D5E08662F00107E7E1800272737272F1F000000|I:466:0EF5FFE6909ED8FFFF48002BBBD8D8FFD8E63A00000048D890FFD8900000000048D848FFD8900000000056FF56FFFFAD0000000048D848FFD8900000000048D848FFD8900000000048D848FFD8900000000048D848FFD8900000000056FF81FFFFAD000000009ED8D8FFD8BB000000C9FFD881C9D8FFD8000048651D00002B7356003A2B3A2B2B3A2B3A2B2B|M:1062:E7FFFF10000000CFFFB740FFFF87000040FFFF5800DFBFC700009FDFDF0000FFCFFF6038FFF7FF0000FFD7C7DFC7FFEFFF0000DF5097DFDF60BFDF0000FF509FDFFF08EFFF0000FF5020EF7700EFFF0000DF4000870800BFDF0000FF5000000018F7FF0097FFC70800089FFFFF7FDFA7DF200020DF9FBFBF3000300838303800083000002030000838100000|P:691:FFFF7B86FFFFD4B30B0086FFFFDFBE4EBEFFEB0B00C9FFDF0B0016DFFF7B00A8FFDF000000A8F6C900A8FFDF000000EBFFC900A8FFDF00007BFFFF7B0086DFB39CA8B3DFBE0B00A8FFDFFFFFDFDF220000A8FFDF4E381600000000B3FFDF380000000000A8FFFFDFDF4300000000A8861659A8430000000000000022382D000000000038380000002D380B00|L:691:FFFF86A8FF700000000059FFFFDF860B0000000000B3DFDF38000000000000A8A8DF38000000000000A8A8DF38000000000000A8A8DF380000000000008686B32D000000000000A8A8DF38000000597B00B3B3DF3800000BF69C0BEBFFDF9C384EEBFF59EBFFFFDFFFFFDFFFFF16A87B004EA8A84E4391000000002D382D00000000002D2D00000B22220000|A:971:000048FF87BFEF000000000010C7EFFF6F000000000000B7E7EF58000000000000FFA7C7BF000000000048FF10BFFF100000000097B700AFD77700000000B76F0067A7AF00000048EFFFEFFFDFEF4800009FBF6F5F6FBFBFA70000F77700000040EFFF10AFFFC7400010A7E7FFA79F386F5F0018A730488F0000000030300000000000002030000038180000|N:794:FFF3C200000092FDAFE988F3FF7500001DFDF34400A5FFF3570000C2CC000092FFE0E93A00C2C2000092FF9CE9FD0AC2C2000092FFAF88FFB9CCC2000075E90A9C92C2E99C000092FF003AD6D6FFC2000092FF00008892FFC200009CFF130000AFCCC2004EE9FFA513000AF3C200576B31921D0000314E000000001D313100000000000A2713000A27270000|C:643:000071B5FFE3EE71D72D0093FFE3B54F93D7FF3966C1FF9F00000044FF39AA9FFF1700000000E339B5E3F900000000000000AAE3E300000000000000AAE3E300000000000000D79FFF0B00000000394FAA71FF7100000000D7AA22B5F9E37D0B2D9FFF2D0022E3E3FFE3FFCC44000000002D715B4F00000000000000000000000000002D2D2D392D2D220B00|H:826:DAECACDAACB6E3A3ECA32DFEFFBF2D2DC8FFFE24009AFF64000088D1E3000088FF5B000088B6E3000088FFACA3A3BFB6E3000088FFD1DADADAB6E3000088FF5B000088B6E3000088FF5B000088B6E3000076FF5B000088BFE30009DAFF880009C8FFF500E3FFECE388BFE3F5FFB66D400949495B4909525B00000012362D0000000000091B1B000924240000|E:696:FFF881C2D8FFE2A2D80041FFFFFFA25661E2FF1600D8F8FF0B00000BE21600D8D8FF0020A200000000D8D8FF2BA2ED00000000D8D8FFD8FF9700000000D8D8FF0B8CFF00000000D8D8FF00000000566100D8D8FF16000000CDB700E2F8FF77000077FFA281FFD8E2D8EDFFF8EDA24156000B416C560B362B000000202B3600000000002B360B00002B360B00|T:710:E8A9C9FFDEC9FFE8B4C9FFFF94DEFFFFD39EFFD3FF94006ABEFF3F00C9D3FF3F006AD3FF35009ED37415006AD3FF3500352A0000006AD3FF350000000000006AD3FF350000000000006AD3FF350000000000006A9EFF350000000000007FF3FF4A00000000004AFDF3E8F320000000002A5F15156A15000000000015353500000000000B351500002A2A0000", "|")
		{
		f := StrSplit(part, ":")
		v := []
		Loop 140
			{
			n := "0x" . SubStr(f[3], A_Index * 2 - 1, 2)
			n += 0
			v.Push(n / 255.0)
			}
		OjTpl[f[1]] := {a: f[2] / 1000.0, v: v}
		}
}

; copies a client-area rectangle of the screen; OjBits holds it (BGRA, top-down)
OjGrab(x, y, w, h) {
	global RobloxHwnd, OjDC, OjBM, OjBits, OjGW, OjGH, OjGX, OjGY, OjOwnBits, OjDW, OjDH, OjBandN, OjBandKey
	if (!RobloxHwnd or w < 10 or h < 10)
		return false
	RobloxClientRect(RobloxHwnd, wx, wy)
	if (!OjDC or w != OjDW or h != OjDH)
		{
		if (OjDC)
			{
			DllCall("DeleteObject", "Ptr", OjBM)
			DllCall("DeleteDC", "Ptr", OjDC)
			}
		hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
		OjDC := DllCall("CreateCompatibleDC", "Ptr", hdcS, "Ptr")
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt"), NumPut(w, bi, 4, "Int"), NumPut(-h, bi, 8, "Int"), NumPut(1, bi, 12, "UShort"), NumPut(32, bi, 14, "UShort")
		OjOwnBits := 0
		OjBM := DllCall("CreateDIBSection", "Ptr", OjDC, "Ptr", &bi, "UInt", 0, "Ptr*", OjOwnBits, "Ptr", 0, "UInt", 0, "Ptr")
		DllCall("SelectObject", "Ptr", OjDC, "Ptr", OjBM)
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
		OjDW := w, OjDH := h
		}
	hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("BitBlt", "Ptr", OjDC, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcS, "Int", wx + x, "Int", wy + y, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
	OjBits := OjOwnBits, OjGW := w, OjGH := h, OjGX := x, OjGY := y
	OjBandN := (OjBandN = "") ? 1 : OjBandN + 1, OjBandKey := ""
	return true
}

OjPx(x, y) {
	global OjBits, OjGW, OjGH, OjGX, OjGY
	x := Round(x) - OjGX, y := Round(y) - OjGY
	if (x < 0 or y < 0 or x >= OjGW or y >= OjGH)
		return 0
	return NumGet(OjBits + 0, (y * OjGW + x) * 4, "UInt")
}

OjLum(v) {
	return (((v >> 16) & 0xFF) + 2 * ((v >> 8) & 0xFF) + (v & 0xFF)) // 4
}

; a star: dark purple when unlit, white when lit
OjStarPx(v) {
	r := (v >> 16) & 0xFF, g := (v >> 8) & 0xFF, b := v & 0xFF
	return ((b >= 75 and b - g >= 40 and r - g >= 15) or (r > 200 and g > 190 and b > 205))
}

OjSlotX(k) {
	global OjGeo
	return OjGeo.cx + (k - 6.5) * OjGeo.sp * 1.3125
}

OjGeoFits() {
	global OjGeo, RobloxHwnd
	if (!IsObject(OjGeo) or !RobloxHwnd)
		return false
	RobloxClientRect(RobloxHwnd, wx, wy, ww, wh)
	return (ww = OjGeo.ww and wh = OjGeo.wh)
}

; finds the star row: the row with the most star pixels, then 12 tall evenly spaced star spikes on it
OjFindGeom() {
	global RobloxHwnd, OjGeo, OjGeoCand, OjGeoCandT
	static fullT := -999999
	if (!RobloxHwnd)
		return false
	RobloxClientRect(RobloxHwnd, wx, wy, ww, wh)
	if (ww < 300 or wh < 300)
		return false
	; a place found once and waiting to be confirmed, then the last place found: look there first. Without this a
	; board only the wide look finds (another UI size or window shape) could never be confirmed - the wide look
	; runs once every 1.5 s, but the second sighting has to come within 0.4 s
	if (IsObject(OjGeoCand) and A_TickCount - OjGeoCandT < 400 and OjGeoCand.ww = ww and OjGeoCand.wh = wh
		and OjFindNear(OjGeoCand, ww, wh))
		return true
	if (IsObject(OjGeo) and OjGeo.ww = ww and OjGeo.wh = wh and OjFindNear(OjGeo, ww, wh))
		return true
	; then a small look where the board sits at the usual UI size (quick), the whole lower screen only now and then
	sp := 0.0615 * wh
	gx := Round(ww / 2 - 8.8 * sp)
	if (gx >= 0 and OjFindIn(gx, Round(0.7389 * wh - 0.9 * sp), Round(17.6 * sp), Round(1.8 * sp), ww, wh))
		return true
	if (A_TickCount - fullT < 1500)
		return false
	fullT := A_TickCount
	; the wide look is far wider than the board, so the share of star pixels on its row is judged against a board
	; of at least 0.6x the usual size, not against the whole width (that asked for 30% of the screen's width)
	return OjFindIn(Round(ww * 0.05), Round(wh * 0.40), Round(ww * 0.90), Round(wh * 0.55), ww, wh, 0.30 * (0.6 * 17.6 * sp) / 4)
}

; a small look round a place found before (its own size, so any UI size)
OjFindNear(c, ww, wh) {
	gx := Round(c.cx - 8.8 * c.sp), gy := Round(c.y - 0.9 * c.sp), gw := Round(17.6 * c.sp), gh := Round(1.8 * c.sp)
	if (gx < 0)
		gw += gx, gx := 0
	if (gy < 0)
		gh += gy, gy := 0
	if (gx + gw > ww)
		gw := ww - gx
	return OjFindIn(gx, gy, gw, gh, ww, wh)
}

OjFindIn(gx, gy, gw, gh, ww, wh, minN := "") {
	global OjGeo, OjBits, OjGeoCand, OjGeoCandT, OjGeoSeen
	if (gy + gh > wh)
		gh := wh - gy
	if (!OjGrab(gx, gy, gw, gh))
		return false
	best := -1, bestN := 0
	Loop 2
		{
		pass := A_Index
		y := (pass = 1) ? 0 : ((best - 4 < 0) ? 0 : best - 4)
		yEnd := (pass = 1) ? gh - 1 : ((best + 4 > gh - 1) ? gh - 1 : best + 4)
		ys := (pass = 1) ? 4 : 1
		xs := (pass = 1) ? 8 : 4
		if (pass = 2)
			bestN := 0
		while (y <= yEnd)
			{
			n := 0, p := OjBits + y * gw * 4, x := 0
			while (x < gw)
				{
				v := NumGet(p + 0, x * 4, "UInt"), r := (v >> 16) & 0xFF, g := (v >> 8) & 0xFF, b := v & 0xFF
				if ((b >= 75 and b - g >= 40 and r - g >= 15) or (r > 200 and g > 190 and b > 205))
					n++
				x += xs
				}
			if (n > bestN)
				best := y, bestN := n
			y += ys
			}
		if (best < 0)
			return false
		}
	if (minN = "" or minN > 0.30 * (gw / 4))
		minN := 0.30 * (gw / 4)
	if (bestN < minN)
		return false
	dy := Round(wh * 0.028)
	st := (dy // 15 < 1) ? 1 : dy // 15
	need := Round(0.35 * ((2 * dy) // st + 1))
	peaks := [], run := false, s0 := 0, x := 0
	while (x < gw)
		{
		e := 0, yy := best - dy
		while (yy <= best + dy)
			{
			if (yy >= 0 and yy < gh)
				{
				v := NumGet(OjBits + 0, (yy * gw + x) * 4, "UInt"), r := (v >> 16) & 0xFF, g := (v >> 8) & 0xFF, b := v & 0xFF
				if ((b >= 75 and b - g >= 40 and r - g >= 15) or (r > 200 and g > 190 and b > 205))
					e++
				}
			yy += st
			}
		if (e >= need)
			{
			if (!run)
				s0 := x, run := true
			}
		else if (run)
			{
			peaks.Push((s0 + x - 2) / 2)
			run := false
			}
		x += 2
		}
	if (peaks.Length() < 12)
		return false
	if (peaks.Length() > 12)
		{
		; the glow round a star that just lit can add a blip - keep the 12 that sit evenly spaced
		ds := []
		Loop % peaks.Length() - 1
			ds.Push(peaks[A_Index + 1] - peaks[A_Index])
		spm := MedianOf(ds)
		chosen := ""
		for i, p0 in peaks
			{
			got := []
			Loop 12
				{
				want := p0 + (A_Index - 1) * spm, bd := 0.15 * spm, bp := ""
				for j, pv in peaks
					{
					if (Abs(pv - want) <= bd)
						bd := Abs(pv - want), bp := pv
					}
				if (bp = "")
					break
				got.Push(bp)
				}
			if (got.Length() = 12)
				{
				chosen := got
				break
				}
			}
		if (!IsObject(chosen))
			return false
		peaks := chosen
		}
	sp := (peaks[12] - peaks[1]) / 11
	Loop 11
		{
		if (Abs(peaks[A_Index + 1] - peaks[A_Index] - sp) > 0.15 * sp)
			return false
		}
	sy := gy + best
	if (sy + 2.7 * sp >= wh)
		return false
	cxs := []
	for i, v in peaks
		cxs.Push(gx + v)
	cand := {y: sy, xs: cxs, sp: sp, cx: (cxs[1] + cxs[12]) / 2, ww: ww, wh: wh}
	; the board grows and slides in when a fight starts: only a place found the same twice in a row counts
	if (IsObject(OjGeoCand) and A_TickCount - OjGeoCandT < 400 and OjGeoCand.wh = wh and Abs(OjGeoCand.sp - sp) <= 0.01 * sp and Abs(OjGeoCand.y - sy) <= 2
		and Abs(OjGeoCand.cx - cand.cx) <= 3)
		{
		OjGeo := cand, OjGeoCand := "", OjGeoSeen := false
		return true
		}
	OjGeoCand := cand, OjGeoCandT := A_TickCount
	return false
}

; time for another look for the board? (every 0.3 s; 0.08 s while a place found once waits to be confirmed)
OjFindDue() {
	global OjLastFind, OjGeoCand, OjGeoCandT
	if (OjLastFind != "" and A_TickCount - OjLastFind < ((IsObject(OjGeoCand) and A_TickCount - OjGeoCandT < 400) ? 80 : 300))
		return false
	OjLastFind := A_TickCount
	return true
}

; the band with the stars, the planchette and the tokens
OjGrabBand() {
	global OjGeo, OjBits, OjGW, OjGH, OjGX, OjGY, OjBandN, OjBandKey, pNoteBits, NoteOriginX, NoteOriginY, NoteW, NoteFullH, NoteBlitAt, QpcFreq, SpecialRod
	x0 := Round(OjGeo.cx - 8.2 * OjGeo.sp)
	y0 := Round(OjGeo.y - 0.15 * OjGeo.sp)
	x0 := (x0 < 0) ? 0 : x0, y0 := (y0 < 0) ? 0 : y0
	w := Round(16.4 * OjGeo.sp), h := Round(2.95 * OjGeo.sp)
	; the Stellarwave capture of this frame already holds the band at the usual UI sizes - read it there, no extra copy
	if (pNoteBits and SpecialRod = "Stellarwave Melody" and NoteBlitAt and x0 >= NoteOriginX and y0 >= NoteOriginY
		and x0 + w <= NoteOriginX + NoteW and y0 + h <= NoteOriginY + NoteFullH)
		{
		DllCall("QueryPerformanceCounter", "Int64*", qn)
		if ((qn - NoteBlitAt) * 1000.0 / QpcFreq < 25)
			{
			OjBits := pNoteBits, OjGW := NoteW, OjGH := NoteFullH, OjGX := NoteOriginX, OjGY := NoteOriginY
			if (OjBandKey != NoteBlitAt)
				OjBandKey := NoteBlitAt, OjBandN := (OjBandN = "") ? 1 : OjBandN + 1
			return true
			}
		}
	return OjGrab(x0, y0, w, h)
}

OjStarsOk() {
	global OjGeo
	n := 0
	for i, x in OjGeo.xs
		{
		if (OjStarPx(OjPx(x, OjGeo.y)))
			n++
		}
	return (n >= 9)
}

; stars light from the left
OjLit() {
	global OjGeo
	n := 0
	for i, x in OjGeo.xs
		{
		if (OjLum(OjPx(x, OjGeo.y)) <= 180)
			break
		n++
		}
	return n
}

; the planchette (beige heart) - a token under it is not read (its line cuts through the letter)
OjHeartX() {
	global OjGeo, OjBits, OjGW, OjGH, OjGX, OjGY, OjBandN
	static at := "", v := -9999
	; the bar reader and the letter reader both want it - read once per frame
	if (OjBandN != "" and at = OjBandN)
		return v
	at := OjBandN, v := OjHeartRead()
	return v
}

OjHeartRead() {
	global OjGeo, OjBits, OjGW, OjGH, OjGX, OjGY, OjPl
	OjCols()
	c1 := OjPl[1], c2 := OjPl[2]
	y := Round(OjGeo.y + 0.70 * OjGeo.sp) - OjGY
	if (y < 0 or y >= OjGH)
		return -9999
	x := Round(OjGeo.xs[1] - 2 * OjGeo.sp) - OjGX, x1 := Round(OjGeo.xs[12] + 2 * OjGeo.sp) - OjGX
	x := (x < 0) ? 0 : x
	x1 := (x1 > OjGW - 1) ? OjGW - 1 : x1
	p := OjBits + y * OjGW * 4, sum := 0, n := 0
	while (x <= x1)
		{
		v := NumGet(p + 0, x * 4, "UInt"), r := (v >> 16) & 0xFF, g := (v >> 8) & 0xFF, b := v & 0xFF
		if ((Abs(r - c1[1]) <= c1[4] and Abs(g - c1[2]) <= c1[4] and Abs(b - c1[3]) <= c1[4])
			or (Abs(r - c2[1]) <= c2[4] and Abs(g - c2[2]) <= c2[4] and Abs(b - c2[3]) <= c2[4]))
			sum += x, n++
		x += 3
		}
	return (n >= 4) ? OjGX + sum / n : -9999
}

; a token sits in slot k: a neutral white rim on its left and on its right (the bare bar is beige or black)
OjPresent(k) {
	global OjGeo
	sx := OjSlotX(k), yc := OjGeo.y + 2.12 * OjGeo.sp, d := 0.08 * OjGeo.sp
	return (OjRim(sx - 0.56 * OjGeo.sp, sx - 0.38 * OjGeo.sp, yc, d) and OjRim(sx + 0.38 * OjGeo.sp, sx + 0.56 * OjGeo.sp, yc, d))
}

OjRim(xa, xb, yc, d) {
	for i, y in [yc - d, yc, yc + d]
		{
		x := Round(xa)
		while (x <= xb)
			{
			v := OjPx(x, y), r := (v >> 16) & 0xFF, g := (v >> 8) & 0xFF, b := v & 0xFF
			if ((r + 2 * g + b) // 4 > 140 and Abs(r - b) < 25)
				return true
			x++
			}
		}
	return false
}

; a used token: its small bottom circle turned white
OjUsed(k) {
	global OjGeo
	sx := OjSlotX(k), sy := OjGeo.y + 2.54 * OjGeo.sp, s := 0.03 * OjGeo.sp, t := 0
	for i, dx in [-s, 0, s]
		{
		for j, dy in [-s, 0, s]
			t += OjLum(OjPx(sx + dx, sy + dy))
		}
	return (t / 9 > 190)
}

; the letter in slot k as a 10x14 coverage grid, read inside a circle a bit smaller than the token's rim
OjGlyph(k, ByRef cov, ByRef asp) {
	global OjGeo, OjBits, OjGW, OjGH, OjGX, OjGY
	sx := OjSlotX(k) - OjGX, cy := OjGeo.y + 2.12 * OjGeo.sp - OjGY, r := 0.42 * OjGeo.sp
	x0 := Floor(sx - r), x1 := Floor(sx + r)
	yt := OjGeo.y + 1.62 * OjGeo.sp - OjGY
	y0 := Floor((yt > cy - r) ? yt : cy - r), y1 := Floor(cy + r * 0.35)
	if (x0 < 0 or y0 < 0 or x1 >= OjGW or y1 >= OjGH)
		return false
	r2 := r * r
	VarSetCapacity(pts, (x1 - x0 + 1) * (y1 - y0 + 1) * 4, 0)
	n := 0, bx0 := 99999, bx1 := -1, by0 := 99999, by1 := -1
	y := y0
	while (y < y1)
		{
		dy2 := (y - cy) * (y - cy), p := OjBits + y * OjGW * 4, x := x0
		while (x < x1)
			{
			if ((x - sx) * (x - sx) + dy2 <= r2)
				{
				v := NumGet(p + 0, x * 4, "UInt")
				if ((((v >> 16) & 0xFF) + 2 * ((v >> 8) & 0xFF) + (v & 0xFF)) // 4 > 170)
					{
					NumPut(x, pts, n * 4, "UShort"), NumPut(y, pts, n * 4 + 2, "UShort"), n++
					if (x < bx0)
						bx0 := x
					if (x > bx1)
						bx1 := x
					if (y < by0)
						by0 := y
					by1 := y
					}
				}
			x++
			}
		y++
		}
	if (n < 40 or by1 - by0 + 1 < 0.30 * OjGeo.sp)
		return false
	bw := bx1 - bx0 + 1, bh := by1 - by0 + 1
	grid := []
	Loop 140
		grid.Push(0)
	Loop % n
		{
		gx := (NumGet(pts, (A_Index - 1) * 4, "UShort") - bx0) * 10 // bw
		gy := (NumGet(pts, (A_Index - 1) * 4 + 2, "UShort") - by0) * 14 // bh
		gx := (gx > 9) ? 9 : gx
		gy := (gy > 13) ? 13 : gy
		grid[gy * 10 + gx + 1] += 1
		}
	cw := bw / 10 * bh / 14
	cov := []
	Loop 140
		cov.Push((grid[A_Index] / cw > 1) ? 1 : grid[A_Index] / cw)
	asp := bw / bh
	return true
}

; the letter that matches clearly ("" if none or too close to call)
OjMatch(cov, asp) {
	global OjTpl
	OjTplInit()
	b1 := 99999, b2 := 99999, bl := ""
	for L, t in OjTpl
		{
		d := 40 * Abs(asp - t.a), v := t.v
		Loop 140
			d += Abs(cov[A_Index] - v[A_Index])
		if (d < b1)
			b2 := b1, b1 := d, bl := L
		else if (d < b2)
			b2 := d
		}
	return (b1 <= 35 and b2 - b1 >= 5) ? bl : ""
}

; is the ouija minigame on screen? (cheap once its place is known)
OjSeen() {
	global OjGeo, OjLastFind
	if (OjGeoFits())
		return (OjGrabBand() and OjStarsOk())
	if (!OjFindDue())
		return false
	return OjFindGeom()
}

OjClick(k) {
	global OjGeo, RobloxHwnd, PrecisionDown, PrecisionUpAt, LookDownX, LookDownY
	if (!RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return false
	VarSetCapacity(pt, 8, 0)
	NumPut(Round(OjSlotX(k)), pt, 0, "Int"), NumPut(Round(OjGeo.y + 1.95 * OjGeo.sp), pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	sx := NumGet(pt, 0, "Int"), sy := NumGet(pt, 4, "Int")
	NumPut(Round(LookDownX), pt, 0, "Int"), NumPut(Round(LookDownY), pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	nx := NumGet(pt, 0, "Int"), ny := NumGet(pt, 4, "Int")
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		PreciseSleep(20)
		}
	CoordMode, Mouse, Screen
	MouseMove, %sx%, %sy%, 0
	PreciseSleep(TA("ojhover", 25))
	MouseMove, % sx + 1, % sy, 0
	PreciseSleep(15)
	send {lbutton down}
	PreciseSleep(TA("ojhold", 60))
	send {lbutton up}
	PreciseSleep(20)
	MouseMove, %nx%, %ny%, 0
	CoordMode, Mouse, Client
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	return true
}

; one fight frame: read the stars, keep each spot's letter up to date, click the letter that is due
OjStep() {
	global OjGeo, OjCache, OjPend, OjMiss, OjClickAt, OjClickLit, OjClickK, OjTry, OjStarsVis, OjStarSeenT, OjNextRd, OjLastFind, OjStarsMissN
	global SwPanelTxt, SwPanelLast, SwClickSigns, RobloxHwnd
	static WORD := "GRIMPLANCHET"
	now := A_TickCount
	if (!OjGeoFits())
		{
		OjStarsVis := false
		if (!OjFindDue())
			return
		if (!OjFindGeom())
			return
		}
	if (!OjGrabBand())
		return
	if (!OjStarsOk())
		{
		OjStarsVis := false
		; not there for a while although the fight goes on: the row may have moved - look for it again
		OjStarsMissN := OjStarsMissN + 1
		if (OjStarsMissN >= 8 and OjFindDue())
			OjFindGeom()
		return
		}
	OjStarsMissN := 0
	OjStarsVis := true
	OjStarSeenT := now
	lit := OjLit()
	SwPanelTxt := lit . "/12 lit" . ((lit < 12) ? ", next " . SubStr(WORD, lit + 1, 1) : "")
	SwPanelLast := SwPanelTxt
	if (lit >= 12 or !SwClickSigns)
		return
	waiting := false
	if (OjClickAt)
		{
		if (lit > OjClickLit)
			OjClickAt := 0, OjTry := 0
		else if (now - OjClickAt < TA("ojwait", 600))
			waiting := true
		else
			OjClickAt := 0
		}
	hx := OjHeartX()
	tsp := OjGeo.sp * 1.3125
	used := {}
	budget := 2
	Loop 12
		{
		k := Mod(OjNextRd + A_Index - 2, 12) + 1
		if (!OjPresent(k))
			{
			OjMiss[k] := OjMiss[k] + 1
			if (OjMiss[k] >= 2)
				OjCache.Delete(k), OjPend.Delete(k)
			continue
			}
		OjMiss[k] := 0
		if (OjUsed(k))
			{
			used[k] := 1
			OjCache.Delete(k), OjPend.Delete(k)
			continue
			}
		if (OjCache.HasKey(k) or budget <= 0 or Abs(OjSlotX(k) - hx) < 0.6 * tsp)
			continue
		if (!OjGlyph(k, cov, asp))
			continue
		budget--
		L := OjMatch(cov, asp)
		if (L != "")
			{
			; a letter counts once it is read the same way twice
			if (OjPend[k] = L)
				OjCache[k] := L
			OjPend[k] := L
			}
		}
	OjNextRd := Mod(OjNextRd, 12) + 1
	if (waiting)
		return
	tgt := SubStr(WORD, lit + 1, 1)
	pick := 0
	for k, L in OjCache
		{
		if (L = tgt and !used.HasKey(k))
			{
			if (pick)
				return
			pick := k
			}
		}
	if (!pick)
		return
	if (pick = OjClickK and lit = OjClickLit and OjTry >= 3)
		{
		; three clicks did not light its star - read that token again before trying more
		OjCache.Delete(pick), OjPend.Delete(pick)
		OjTry := 0
		return
		}
	if (OjClick(pick))
		{
		if (pick != OjClickK or lit != OjClickLit)
			OjTry := 0
		OjTry := OjTry + 1
		OjClickK := pick, OjClickLit := lit, OjClickAt := A_TickCount
		}
}

; The ouija bar and fish (instead of the Stellarwave ones). The bar is a rounded box whose two thin grey inner rims
; run its whole length, on a wooden track; tokens, their glow and the planchette's line hide parts of it, so its
; spot is where it covers the most rim and the least wood. The fish is the planchette (the beige heart).
OjBarScan(now) {
	global OjGeo, OjLastFind, OjTipT, MgInPlay, SwFound, SwBarL, SwBarW, SwFishX, SwFishHeld, SwPhase, TooltipX, Tooltip13
	global SwPanelTxt, OjGeoSeen, OjBarMissN
	SwFound := false, SwFishX := -1, SwFishHeld := false, SwPhase := 0
	OjCols()
	if (!OjGeoFits())
		{
		if (SwPanelTxt = "" or InStr(SwPanelTxt, "ouija"))
			SwPanelTxt := "ouija board not found yet"
		if (!OjFindDue() or !OjFindGeom())
			return
		}
	if (!OjGrabBand())
		return
	; before the fight its stars must show (nothing else on screen counts), during it a frame without them still reads
	st := OjStarsOk()
	if (!st and (SwPanelTxt = "" or InStr(SwPanelTxt, "ouija")))
		SwPanelTxt := "ouija stars not on screen"
	if (st)
		OjGeoSeen := true, OjBarMissN := 0
	else
		{
		; no stars where the board was found: during a fight, or if they were never seen there, look for it again
		OjBarMissN := (OjBarMissN = "") ? 1 : OjBarMissN + 1
		if ((MgInPlay or !OjGeoSeen) and OjBarMissN >= 4 and OjFindDue())
			{
			OjFindGeom()
			return
			}
		}
	if (!MgInPlay and !st)
		return
	hx := OjHeartX()
	if (hx > -9999)
		SwFishX := Round(hx)
	yA := OjRimRow()
	if (yA >= 0)
		OjBarFit(yA)
	if (MgInPlay and now - OjTipT >= 0.25)
		{
		OjTipT := now
		tooltip, % "Ominous Ouija: bar " . (SwFound ? "found" : "not found") . ", planchette " . ((SwFishX >= 0) ? "found" : "not found"), %TooltipX%, %Tooltip13%, 13
		}
}

; the bar's upper inner rim row (the lower one is 0.43 star spacings below it), looked for each frame: the board
; slides up into place at the start of every fight. -1 if fewer than 3 of 25 spots along the track agree
OjRimRow() {
	global OjGeo, OjBits, OjGW, OjGH, OjGX, OjGY, OjRimR, OjRimG, OjRimB, OjRimT
	t := OjRimT + 4
	sp := OjGeo.sp, dB := Round(0.4292 * sp), d := Round(0.04 * sp)
	d := (d < 2) ? 2 : d
	ya := Round(OjGeo.y + 1.86 * sp) - OjGY, yz := Round(OjGeo.y + 2.06 * sp) - OjGY
	if (ya - d < 0 or yz + dB + d + 1 >= OjGH)
		return -1
	ys := []
	; looked at on the token spots and halfway between them: with all 12 tokens out, the gaps still show it
	Loop 25
		{
		x := Round(OjGeo.cx + (A_Index - 13) * 0.65625 * sp) - OjGX
		if (x < 0 or x >= OjGW)
			continue
		y := ya
		while (y <= yz)
			{
			v := NumGet(OjBits + 0, (y * OjGW + x) * 4, "UInt")
			if (Abs(((v >> 16) & 0xFF) - OjRimR) <= t and Abs(((v >> 8) & 0xFF) - OjRimG) <= t and Abs((v & 0xFF) - OjRimB) <= t
				and OjRimPx(OjBits + ((y + dB) * OjGW + x) * 4, t) and !OjRimPx(OjBits + ((y - d) * OjGW + x) * 4, t)
				and !OjRimPx(OjBits + ((y + d + 1) * OjGW + x) * 4, t))
				{
				ys.Push(y)
				break
				}
			y++
			}
		}
	n := ys.Length()
	if (n < 3)
		return -1
	i := 2
	while (i <= n)
		{
		v := ys[i], j := i - 1
		while (j >= 1 and ys[j] > v)
			ys[j + 1] := ys[j], j--
		ys[j + 1] := v
		i++
		}
	m := ys[(n + 1) // 2], agree := 0
	for i, v in ys
		agree += (Abs(v - m) <= 1) ? 1 : 0
	return (agree >= 3) ? OjGY + m + Floor(0.012 * sp) : -1
}

; the rims' grey (the Bar color box, 0x959088 for this preset)
OjRimPx(p, t) {
	global OjRimR, OjRimG, OjRimB
	v := NumGet(p + 0, 0, "UInt")
	return (Abs(((v >> 16) & 0xFF) - OjRimR) <= t and Abs(((v >> 8) & 0xFF) - OjRimG) <= t and Abs((v & 0xFF) - OjRimB) <= t)
}

; the preset's colours, from the Stellarwave color boxes (they hold the ouija ones while this preset is picked):
; Bar color = the bar's grey rims, Fish color and Fish head color = the planchette
OjCols() {
	global StellarBarColors, StellarBarTol, StellarFishColors, StellarFishTol, StellarHeadColors, StellarHeadTol
	global OjRimR, OjRimG, OjRimB, OjRimT, OjPl, OjPrmRim
	static key := "-"
	k := StellarBarColors . "|" . StellarBarTol . "|" . StellarFishColors . "|" . StellarFishTol . "|" . StellarHeadColors . "|" . StellarHeadTol
	if (k == key)
		return
	key := k
	c := OjCol(StellarBarColors, 0x959088)
	OjRimR := (c >> 16) & 0xFF, OjRimG := (c >> 8) & 0xFF, OjRimB := c & 0xFF, OjRimT := OjTol(StellarBarTol, 14)
	VarSetCapacity(OjPrmRim, 48, 0)
	PcPrmAt(&OjPrmRim, OjRimR, OjRimG, OjRimB, OjRimT, 0)
	OjPl := []
	for i, f in [[StellarFishColors, 0xD4C5A4, StellarFishTol, 40], [StellarHeadColors, 0xE8E1C5, StellarHeadTol, 30]]
		{
		c := OjCol(f[1], f[2])
		OjPl.Push([(c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF, OjTol(f[3], f[4])])
		}
}

; first colour in a box ("0x959088", "#959088", ...), or the default
OjCol(s, d) {
	if (RegExMatch(s, "i)(?:0x|#)?([0-9a-f]{6})(?![0-9a-f])", m))
		return ("0x" . m1) + 0
	return d
}

OjTol(v, d) {
	if v is not number
		return d
	v := Round(v)
	return (v < 0) ? 0 : ((v > 255) ? 255 : v)
}

; the bar's spot from the rims on both rim rows (rim), the wood beside it (not bar), everything else unknown.
; Its length is measured when wood shows right next to both ends, and kept (10.68 star spacings until then)
OjBarFit(yA) {
	global OjGeo, OjBits, OjGW, OjGH, OjGX, OjGY, OjBarW, OjBarWH, OjBarRing, OjBarL, SwFound, SwBarL, SwBarW
	global OjPrmRim, OjRimR, OjRimG, OjRimB, OjRimT
	sp := OjGeo.sp, yB := yA + Round(0.4292 * sp)
	if (yA - OjGY < 0 or yB - OjGY >= OjGH)
		return
	x0 := Round(OjGeo.cx - 8.2 * sp) - OjGX, x1 := Round(OjGeo.cx + 8.2 * sp) - OjGX
	x0 := (x0 < 0) ? 0 : x0
	x1 := (x1 > OjGW - 1) ? OjGW - 1 : x1
	pa := OjBits + (yA - OjGY) * OjGW * 4, pb := OjBits + (yB - OjGY) * OjGW * 4
	ra := [], rb := []
	OjRuns(pa, x0, x1, &OjPrmRim, ra)
	OjRuns(pb, x0, x1, &OjPrmRim, rb)
	Rims := [], mn := Round(0.05 * sp)
	mn := (mn < 3) ? 3 : mn
	for i, v in OjAnd(ra, rb)
		{
		; a few rim-grey pixels can come from the wood's grain
		if (v[2] - v[1] + 1 >= mn)
			Rims.Push(v)
		}
	; wood: warm (red well above blue) and not too dark, on either rim row
	st := Round(0.045 * sp)
	st := (st < 2) ? 2 : st
	n := (x1 - x0) // st + 1
	Woods := [], ks := -1, ke := -1
	Loop % n
		{
		x := x0 + (A_Index - 1) * st
		v := NumGet(pa + 0, x * 4, "UInt"), r := (v >> 16) & 0xFF, g := (v >> 8) & 0xFF, b := v & 0xFF
		wd := (r - b >= 16 and r >= 60 and !(Abs(r - OjRimR) <= OjRimT and Abs(g - OjRimG) <= OjRimT and Abs(b - OjRimB) <= OjRimT))
		if (!wd)
			{
			v := NumGet(pb + 0, x * 4, "UInt"), r := (v >> 16) & 0xFF, g := (v >> 8) & 0xFF, b := v & 0xFF
			wd := (r - b >= 16 and r >= 60 and !(Abs(r - OjRimR) <= OjRimT and Abs(g - OjRimG) <= OjRimT and Abs(b - OjRimB) <= OjRimT))
			}
		if (!wd)
			continue
		if (ke = x - 1)
			ke := x + st - 1
		else
			{
			if (ks >= 0)
				Woods.Push([ks, ke])
			ks := x, ke := x + st - 1
			}
		}
	if (ks >= 0)
		Woods.Push([ks, ke])
	; the bar's rounded ends show its beige inside on the rim rows: wood right next to a rim does not count
	gk := Round(0.12 * sp)
	for i, v in Rims
		{
		Woods2 := []
		for j, kv in Woods
			{
			if (kv[2] < v[1] - gk or kv[1] > v[2] + gk)
				Woods2.Push(kv)
			else
				{
				if (kv[1] < v[1] - gk)
					Woods2.Push([kv[1], v[1] - gk - 1])
				if (kv[2] > v[2] + gk)
					Woods2.Push([v[2] + gk + 1, kv[2]])
				}
			}
		Woods := Woods2
		}
	; measure: rim runs joined over gaps without wood, the biggest one, with wood right beside both of its ends
	mr := [], g8 := Round(0.08 * sp)
	for i, v in Rims
		{
		q := mr.Length()
		if (q and (v[1] - mr[q][2] - 1 <= g8 or !SwCover(Woods, mr[q][2] + 1, v[1] - 1)))
			mr[q][2] := v[2], mr[q][3] := mr[q][3] + v[2] - v[1] + 1
		else
			mr.Push([v[1], v[2], v[2] - v[1] + 1])
		}
	bi := 0
	for i, v in mr
		{
		if (!bi or v[3] > mr[bi][3])
			bi := i
		}
	if (bi)
		{
		a := mr[bi][1], e := mr[bi][2], wm := e - a + 1, ww := Round(0.45 * sp)
		if (wm >= 5 * sp and wm <= 14 * sp and SwCover(Woods, a - ww, a - 1) >= 0.5 * ww and !SwCover(Rims, a - ww, a - 1)
			and SwCover(Woods, e + 1, e + ww) >= 0.5 * ww and !SwCover(Rims, e + 1, e + ww))
			{
			if (!IsObject(OjBarRing) or OjBarWH != OjGeo.wh)
				OjBarRing := [], OjBarW := 0, OjBarWH := OjGeo.wh
			OjBarRing.Push(wm)
			if (OjBarRing.Length() > 7)
				OjBarRing.RemoveAt(1)
			srt := []
			for i, v in OjBarRing
				{
				j := srt.Length()
				while (j >= 1 and srt[j] > v)
					j--
				srt.InsertAt(j + 1, v)
				}
			med := srt[(srt.Length() + 1) // 2], agree := 0
			for i, v in srt
				agree += (Abs(v - med) <= 0.015 * med) ? 1 : 0
			if (agree >= 3)
				OjBarW := med
			}
		}
	; fit: slide a bar of that length along the track (in steps of st) - 4 per rim pixel inside, -1 per wood pixel
	BarLen := (OjBarW and OjBarWH = OjGeo.wh) ? OjBarW : Round(10.68 * sp)
	Rc := [], Kc := []
	Loop % n
		Rc.Push(0), Kc.Push(0)
	for i, v in Rims
		{
		c := (v[1] - x0) // st
		while (c < n and x0 + c * st <= v[2])
			{
			ca := x0 + c * st, ce := ca + st - 1
			Rc[c + 1] := Rc[c + 1] + ((v[2] < ce) ? v[2] : ce) - ((v[1] > ca) ? v[1] : ca) + 1
			c++
			}
		}
	for i, v in Woods
		{
		c := (v[1] - x0) // st
		while (c < n and x0 + c * st <= v[2])
			Kc[c + 1] := st, c++
		}
	PR := [0], PK := [0]
	Loop % n
		PR.Push(PR[A_Index] + Rc[A_Index]), PK.Push(PK[A_Index] + Kc[A_Index])
	Wc := Round(BarLen / st), m := Round(0.5 * sp / st)
	prev := (OjBarL > -9999), L := m - Wc, best := "", bL := 0, bE := 0, bR := 0
	while (L <= n - m)
		{
		lo := (L < 0) ? 0 : L, hi := (L + Wc > n) ? n : L + Wc
		inR := PR[hi + 1] - PR[lo + 1]
		sc := 4 * inR - (PK[hi + 1] - PK[lo + 1])
		if (prev)
			sc -= 0.02 * Abs(OjGX + x0 + L * st - OjBarL)
		if (best = "" or sc > best + 0.001)
			best := sc, bL := L, bE := L, bR := inR
		else if (Abs(sc - best) <= 0.001 and bE = L - 1)
			bE := L
		L++
		}
	if (bR < sp)
		return
	; an end hidden under tokens leaves a stretch of equally good spots: take its middle
	OjBarL := OjGX + x0 + ((bL + bE) // 2) * st
	SwFound := true, SwBarL := OjBarL, SwBarW := BarLen
}

; runs of one colour along a row (machine code search; a = a PcPrmAt block: the colour, then its inverse)
OjRuns(p, x0, x1, a, rr) {
	x := x0
	while (x <= x1 and rr.Length() < 400)
		{
		i := PcFindAt(p + x * 4, x1 - x + 1, 4, a)
		if (i < 0)
			break
		s := x + i
		j := PcFindAt(p + (s + 1) * 4, x1 - s, 4, a + 24)
		e := (j < 0) ? x1 : s + j
		rr.Push([s, e])
		x := e + 1
		}
}

; the parts two sorted run lists share
OjAnd(a, b) {
	out := [], i := 1, j := 1
	while (i <= a.Length() and j <= b.Length())
		{
		lo := (a[i][1] > b[j][1]) ? a[i][1] : b[j][1]
		hi := (a[i][2] < b[j][2]) ? a[i][2] : b[j][2]
		if (hi >= lo)
			out.Push([lo, hi])
		if (a[i][2] < b[j][2])
			i++
		else
			j++
		}
	return out
}

SwScan() {
	global SwScanned, SwReady, pCaptureBits, CaptureW, CaptureH, pNoteBits, NoteFresh, SwFrameT, SwPreset
	global SwFound, SwBarL, SwBarW, SwFishX, SwPhase, SwPhaseT, SwInvalidT, SwUndarkT, SwStarsValid, SwLit, SwLitPrev, SwLastStep, SwK0, SwClicks, SwStop, SwStopWhy, SwGradOk, SwWRing, SwStarStableT, SwLastClick
	global SwW, SwWMeas, SwMeasN, SwPostT, SwBarHold, SwCleanL, SwCleanW
	if (SwScanned)
		return true
	SwScanned := true
	if (!SwReady)
		SwSetup()
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 40)
		return false
	now := SwNow()
	SwFrameT := now
	if (SwPreset = "Ominous Ouija")
		{
		OjBarScan(now)
		return true
		}
	SwStarsRead(now)
	SwBarScan(now)
	SwFishScan(now)
	dark := SwDarkTest()
	if (SwPhase = 0)
		{
		if (SwStarsValid and dark and SwFound)
			{
			SwPhase := 1
			SwPhaseT := now
			SwInvalidT := 0
			SwUndarkT := 0
			SwPhaseReset()
			SwWMeas := false
			SwMeasN := 0
			SwLitPrev := SwLit
			SwLog("phase start lit=" . SwLit)
			}
		}
	else
		{
		if (SwStarsValid)
			SwInvalidT := 0
		else if (!SwInvalidT)
			SwInvalidT := now
		if (dark)
			SwUndarkT := 0
		else if (!SwUndarkT and now - SwLastClick >= 1.0 and now - SwPhaseT >= 1.0)
			SwUndarkT := now
		if ((SwInvalidT and now - SwInvalidT > 0.2) or (SwUndarkT and now - SwUndarkT > 1.0))
			{
			SwPhase := 0
			SwWRing := []
			SwPostT := now
			if (SwWMeas)
				SwWRing := [SwW]
			SwWMeas := false
			SwMeasN := 0
			SwLog("phase end" . (SwInvalidT ? " stars" : "") . (SwUndarkT ? " undark" : ""))
			SwPreEnd("phase end")
			}
		if (SwPhase and SwStarsValid and SwLit < SwLitPrev)
			{
			if (SwLit = 0)
				{
				SwLog("lit reset " . SwLitPrev . "->0")
				SwPhaseReset()
				SwWMeas := false
				SwMeasN := 0
				SwPhaseT := now
				}
			else
				SwLog("lit dropped " . SwLitPrev . "->" . SwLit . " ignored")
			}
		if (SwStarsValid)
			SwLitPrev := SwLit
		}
	if (SwPhase and SwFound)
		{
		if (!SwGradOk and !SwZoneLen(SwCleanL, SwCleanL + Round(SwCleanW) - 1))
			SwGradLearn()
		SwSlotsScan(now)
		}
	else if (SwPhase and SwBarHold and SwGradOk)
		SwSlotsScan(now, true)
	if (SwPhase and SwLastStep and now - SwLastStep > 1.0 and !SwStop and SwOrderCount() > 0)
		{
		SwStop := true
		SwStopWhy := "gap " . Round((now - SwLastStep) * 1000)
		SwLog("stop: " . SwStopWhy)
		}
	SwLastStep := now
	SwTip(now)
	return true
}

SwOrderCount() {
	global SwOrder
	return SwOrder.Length()
}

SwStarsRead(now) {
	global SwMaxSigns
	global pNoteBits, NoteW, NoteH, NoteOriginX, NoteOriginY, SwS, SwSB, SwSX, WindowWidth, SwPrmWh, SwPrmWhI, SwPrmStU, SwPrmStUI
	global SwStarFound, SwStarY, SwStarX0, SwStarPitch, SwStarRetryT, SwStarV, SwStarT, SwStarsValid, SwLit, SwPitch, SwSlotC0, SwPhase, SwStarOkT, SwLitRaw, SwLitRawT, SwFastClicks
	global SwClickAt, SwClickLit, SwLitFastT, SwLitFastV, SwLitRawN, SwClickSlot, FishBarLeft
	global SwPitchRef, SwPitchRefH, SwStarStableT, WindowHeight, SwStarYRef, SwStarYRefH
	if (!pNoteBits or NoteW < 40 or NoteH < 8)
		{
		SwStarsValid := false
		return
		}
	if (SwStarFound)
		{
		if (SwStarRow(SwStarY, cs, tot))
			SwStarSet(cs)
		else if (!SwPhase)
			{
			SwStarFound := false
			SwStarRetryT := now
			}
		}
	if (!SwStarFound)
		{
		if (SwStarRetryT and now - SwStarRetryT < 0.2)
			{
			SwStarsValid := false
			return
			}
		SwStarRetryT := now
		if (!SwStarFind())
			{
			SwStarsValid := false
			return
			}
		}
	nom := 0.0625 * WindowHeight
	if (SwPitchRef > 0 and SwPitchRefH = WindowHeight and (SwStarPitch < 0.95 * SwPitchRef or SwStarPitch > 1.05 * SwPitchRef) and SwStarStableT and now - SwStarStableT >= 0.3 and SwStarPitch >= 0.90 * nom and SwStarPitch <= 1.05 * nom)
		{
		SwPitchRef := -1
		SwLog("star pitch unlearned " . Round(SwStarPitch, 2))
		}
	learned := (SwPitchRef > 0 and SwPitchRefH = WindowHeight)
	pref := learned ? SwPitchRef : nom
	if (SwStarPitch < 0.95 * pref or SwStarPitch > 1.05 * pref)
		{
		if (learned or SwStarPitch < 0.90 * pref or SwStarPitch > 1.05 * pref or !SwStarStableT or now - SwStarStableT < 0.1)
			{
			SwStarsValid := false
			return
			}
		}
	Loop 12
		{
		x := Round(SwStarX0 + (A_Index - 1) * SwStarPitch) - NoteOriginX
		if (x < 1 or x >= NoteW - 1)
			continue
		p := pNoteBits + (SwStarY * NoteW + x) * 4
		r := 0
		g := 0
		b := 0
		Loop 3
			{
			px := NumGet(p + (A_Index - 2) * 4, 0, "UInt")
			b += px & 0xFF
			g += (px >> 8) & 0xFF
			r += (px >> 16) & 0xFF
			}
		r := r // 3
		g := g // 3
		b := b // 3
		mn := (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
		v := 0
		if (mn >= 200)
			v := 2
		else if (Abs(r - 60) <= 30 and Abs(g - 28) <= 30 and Abs(b - 96) <= 30)
			v := 1
		if (v)
			{
			SwStarV[A_Index] := v
			SwStarT[A_Index] := now
			}
		}
	valid := true
	lit := 0
	pre := true
	Loop 12
		{
		if (now - SwStarT[A_Index] > 0.15)
			valid := false
		if (SwStarV[A_Index] = 2 and pre)
			lit++
		else
			pre := false
		}
	SwStarsValid := valid
	if (valid and !(SwPitchRef > 0 and SwPitchRefH = WindowHeight) and SwStarStableT and now - SwStarStableT >= 0.3 and Abs(SwStarPitch / nom - 1) > 0.01 and SwStarPitch >= 0.95 * nom)
		{
		SwPitchRef := SwStarPitch
		SwPitchRefH := WindowHeight
		SwLog("star pitch learned " . Round(SwStarPitch, 2))
		}
	if (valid)
		{
		SwStarYRef := SwStarY
		SwStarYRefH := WindowHeight
		}
	if (valid)
		{
		if (lit != SwLitRaw)
			{
			if (SwClickAt and SwClickSlot and (lit = SwClickLit + 1 or (SwClickLit = 11 and lit = 0)))
				SwGlowAdd(Round(SwSlotX(SwClickSlot)) - Round(FishBarLeft), now)
			SwLitRaw := lit
			SwLitRawT := now
			SwLitRawN := 1
			}
		else
			SwLitRawN := SwLitRawN + 1
		if (SwLitFastT and now - SwLitFastT < 0.1 and SwLitRaw = SwLitFastV - 1)
			{
			SwLog("star revert " . SwLitFastV . "->" . SwLitRaw)
			SwLitFastT := 0
			}
		if (now - SwLitRawT >= SwSec(SwMaxSigns ? 0 : (SwFastClicks ? 0.03 : 0.1)))
			SwLit := SwLitRaw
		else if (SwClickAt and SwLitRaw = SwClickLit + 1 and SwLit != SwLitRaw and SwLitRawN >= 2)
			{
			SwLit := SwLitRaw
			SwLitFastT := now
			SwLitFastV := SwLitRaw
			}
		SwStarOkT := now
		}
	else if (SwPhase and SwStarOkT and now - SwStarOkT > 0.5)
		{
		SwStarFound := false
		SwStarRetryT := 0
		}
}

SwStarRow(y, ByRef cs, ByRef tot) {
	global pNoteBits, NoteW, NoteH, SwS, SwSB, SwSX, SwPrmWh, SwPrmWhI, SwPrmStU, SwPrmStUI
	cs := []
	tot := 0
	if (y < 0 or y >= NoteH)
		return false
	rr := []
	p := pNoteBits + y * NoteW * 4
	SwRuns(p, 0, NoteW - 1, SwPrmWh, SwPrmWhI, 2, rr)
	SwRuns(p, 0, NoteW - 1, SwPrmStU, SwPrmStUI, 2, rr)
	TryRunsMerge(rr, 2)
	wlo := Round(10 * SwS)
	whi := Round(60 * SwS)
	for i, v in rr
		{
		w := v[2] - v[1] + 1
		if (w >= wlo and w <= whi)
			{
			cs.Push((v[1] + v[2]) / 2)
			tot += w
			}
		}
	if (cs.Length() != 12)
		return false
	pitch := (cs[12] - cs[1]) / 11
	pmin := ((SwS < SwSX) ? SwS : SwSX) * 60
	pmax := ((SwS > SwSX) ? SwS : SwSX) * 120
	if (pitch < pmin or pitch > pmax)
		return false
	Loop 11
		{
		if (Abs(cs[A_Index + 1] - cs[A_Index] - pitch) > 0.08 * pitch)
			return false
		}
	return true
}

SwStarFind() {
	global NoteOriginX, NoteOriginY, NoteH, SwS, SwSB, SwStarFound, SwStarY, SwStarX0, SwStarPitch, SwPitch, SwSlotC0, SwStarYRef, SwStarYRefH, SwStarFullT, WindowHeight
	yn := Round(1060 * SwS) - NoteOriginY
	half := Round(10 * SwS)
	best := 0
	bcs := ""
	Loop % 2 * half + 1
		{
		y := yn - half + A_Index - 1
		if (!SwStarRow(y, cs, tot))
			continue
		if (tot > best)
			{
			best := tot
			SwStarY := y
			bcs := cs
			}
		}
	if (best <= 0)
		{
		by := -1
		if (SwStarYRef >= 0 and SwStarYRefH = WindowHeight)
			best := SwStarRows(SwStarYRef - half, SwStarYRef + half, 1, yn, half, by)
		if (by < 0 and (!SwStarFullT or SwNow() - SwStarFullT >= 1.0 or SwDarkTest()))
			{
			SwStarFullT := SwNow()
			st := Round(2 * SwS)
			if (st < 1)
				st := 1
			best := SwStarRows(0, NoteH - 1, st, yn, half, by)
			}
		if (by >= 0)
			{
			SwStarRow(by, bcs, tot)
			SwStarY := by
			}
		}
	if (best <= 0 or !IsObject(bcs))
		return false
	SwStarFound := true
	SwStarSet(bcs)
	SwLog("stars y=" . (NoteOriginY + SwStarY) . " x0=" . Round(SwStarX0) . " pitch=" . Round(SwStarPitch, 2))
	return true
}

SwPitchOk(p) {
	global SwPitchRef, SwPitchRefH, WindowHeight
	nom := 0.0625 * WindowHeight
	if (p >= 0.90 * nom and p <= 1.05 * nom)
		return true
	return (SwPitchRef > 0 and SwPitchRefH = WindowHeight and p >= 0.95 * SwPitchRef and p <= 1.05 * SwPitchRef)
}

SwStarRows(y0, y1, st, yn, half, ByRef by) {
	best := 0
	by := -1
	y := y0
	while (y <= y1)
		{
		if ((y < yn - half or y > yn + half) and SwStarRow(y, cs, tot) and tot > best and SwPitchOk((cs[12] - cs[1]) / 11))
			{
			best := tot
			by := y
			}
		y += st
		}
	if (by >= 0 and st > 1)
		{
		yc := by
		Loop % 2 * st - 1
			{
			y := yc - st + A_Index
			if (SwStarRow(y, cs, tot) and tot >= best and SwPitchOk((cs[12] - cs[1]) / 11))
				{
				best := tot
				by := y
				}
			}
		}
	return best
}

SwStarSet(cs) {
	global NoteOriginX, SwStarX0, SwStarPitch, SwPitch, SwSlotC0, SwStarStableT, SwSX
	np := (cs[12] - cs[1]) / 11
	if (Abs(np - SwStarPitch) > 0.4 or Abs(NoteOriginX + cs[1] - SwStarX0) > 1.5)
		SwStarStableT := SwNow()
	SwStarX0 := NoteOriginX + cs[1]
	SwStarPitch := np
	SwPitch := SwStarPitch * 1.28333
	if (Abs(SwPitch - 115.5 * SwSX) > 0.01 * 115.5 * SwSX)
		SwPitch := 115.5 * SwSX
	SwSlotC0 := SwStarX0 + 5.5 * SwStarPitch - 5.5 * SwPitch
}

SwFrameTop() {
	global pCaptureBits, CaptureW, CaptureH, SwPrmFr, SwPrmFrI, SwS, SwSB, SwLastC, FishBarLeft, FishBarTop, WindowWidth, WindowHeight, SwXBar, SwXBarN
	y0 := Round(WindowHeight * 0.83) - Round(FishBarTop)
	y1 := Round(WindowHeight * 0.89) - Round(FishBarTop)
	if (y0 < 0)
		y0 := 0
	if (y1 > CaptureH - 12)
		y1 := CaptureH - 12
	need := Round(3 * SwSB)
	if (need < 2)
		need := 2
	span := Round(8 * SwSB)
	cx := (SwLastC >= 0) ? SwLastC : WindowWidth / 2
	found := []
	for i, k in [-3, -2, -1, 1, 2, 3]
		{
		x := Round(cx + k * 0.05 * WindowWidth) - Round(FishBarLeft)
		if (x < 0 or x >= CaptureW)
			continue
		y := SwColScan(x, y0, y1, need, span, &SwPrmFr, &SwPrmFrI)
		Loop % SwXBarN
			{
			yy := SwColScan(x, y0, y1, need, span, &SwXBar + (A_Index - 1) * 48, &SwXBar + (A_Index - 1) * 48 + 24)
			if (yy >= 0 and (y < 0 or yy < y))
				y := yy
			}
		if (y >= 0)
			found.Push(y)
		}
	if (!found.Length())
		return -1
	return Round(SwMedian(found))
}

SwBarScan(now) {
	global SwFrStillRef, SwFrStillT, SwFoundT, SwBarHold, SwLitRawT
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwPrmFr, SwPrmFrI, SwFrTop, SwFrMiss, SwLastC, SwLastL, SwW, SwWSign, SwWRing, SwFound, SwBarL, SwBarW
	global SwPhase, FishBarLeft, FishBarTop, WindowWidth, WindowHeight, SwFrLearned, SwPiano, SwPianoDis, SwCleanL, SwCleanW, SwFrRef, SwFrRefT, SwFrMoveT
	global SwXBar, SwXBarN, SwWMeas, SwMeasN, SwMeasT, SwSM, SwSB, SwFrH, SwFrHC, SwFrT, SwFrTC, SwFrHT, SwFrBad, SwFrOk
	global SwCacheW, SwCacheH, SwCacheSB, SwCacheFrH, SwCacheFrT
	SwGlowZones(now)
	ft := SwFrameTop()
	nom := Round(1208 * SwS) - Round(FishBarTop)
	if (ft >= 0 and ft >= nom - Round(0.01 * WindowHeight) and ft <= nom + Round(0.06 * WindowHeight))
		{
		if (now - SwFrRefT >= 0.2)
			{
			if (SwFrRef >= 0 and Abs(ft - SwFrRef) > 5 * SwSB)
				{
				SwFrMoveT := now
				SwLog("frame top moved " . SwFrRef . "->" . ft)
				}
			SwFrRef := ft
			SwFrRefT := now
			}
		SwFrTop := ft
		SwFrMiss := 0
		if (SwFrStillRef < 0 or Abs(ft - SwFrStillRef) > 3 * SwSB)
			{
			SwFrStillRef := ft
			SwFrStillT := now
			}
		}
	else
		SwFrMiss++
	SwFound := false
	SwBarHold := false
	SwCleanL := -1
	SwCleanW := 0
	if (SwFrMiss > 6)
		{
		SwLastL := -1
		SwLastC := -1
		return
		}
	if (SwFrBad >= 3 and SwFrH > 0)
		{
		SwFrH := -1
		SwFrHC := -1
		SwFrBad := 0
		if (!SwFrOk)
			{
			SwSB := SwSM
			SwFrHT := now + 0.9
			}
		}
	if (SwFrH < 0 and SwFrMiss = 0 and now - SwFrMoveT >= 0.2 and Abs(SwFrTop - SwFrRef) <= 1 and now - SwFrHT >= 0.1)
		{
		SwFrHT := now
		SwFrameBot(SwFrTop, t0, t1, b0, b1)
		h2 := b0 + b1
		tcn := (t0 + t1) // 2
		if (b0 > 0 and SwFrHC > 0 and Abs(h2 - SwFrHC) <= 2 and Abs(tcn - SwFrTC) <= 1)
			{
			SwSB := (Abs(h2 / (168.0 * SwSM) - 1) > 0.03) ? h2 / 168.0 : SwSM
			ob := Round(84 * SwSB)
			SwFrH := (b0 <= ob and ob <= b1) ? ob : (h2 + 1) // 2
			ot := Round(2 * SwSB)
			SwFrT := (t0 <= ot and ot <= t1) ? ot : (t0 + t1 + 1) // 2
			SwFrOk := false
			SwLog("bar rows " . b0 . "-" . b1 . " top " . t0 . "-" . t1 . " sb " . Round(SwSB, 3))
			}
		SwFrHC := (b0 > 0) ? h2 : -1
		SwFrTC := (b0 > 0) ? tcn : -1
		}
	yt := SwFrTop + ((SwFrH > 0) ? SwFrT : Round(2 * SwSB))
	yb := SwFrTop + ((SwFrH > 0) ? SwFrH : Round(84 * SwSB))
	if (yt < 0 or yb >= CaptureH)
		return
	ra := []
	rb := []
	xa := Round(WindowWidth * 0.225) - Round(FishBarLeft)
	xb := Round(WindowWidth * 0.775) - Round(FishBarLeft)
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	SwRuns(pCaptureBits + yt * CaptureW * 4, xa, xb, SwPrmFr, SwPrmFrI, 3, ra)
	SwRuns(pCaptureBits + yb * CaptureW * 4, xa, xb, SwPrmFr, SwPrmFrI, 3, rb)
	if (SwXBarN)
		{
		SwRunsX(pCaptureBits + yt * CaptureW * 4, xa, xb, &SwXBar, SwXBarN, 3, ra)
		SwRunsX(pCaptureBits + yb * CaptureW * 4, xa, xb, &SwXBar, SwXBarN, 3, rb)
		}
	L := -1
	w := 0
	Wp := Round(WindowHeight * 0.625)
	if (SwPhase and !SwWMeas)
		SwW := Wp
	if (SwCleanFrame(ra, rb, yt, yb, cl, cw, now))
		{
		SwCleanL := cl
		SwCleanW := cw
		if (SwPhase)
			{
			if (!SwWMeas)
				{
				if (cw < 0.95 * Wp)
					{
					if (SwMeasN > 0 and now - SwMeasT > 0.3)
						SwMeasN := 0
					SwMeasN++
					SwMeasT := now
					one := false
					pc := SwPianoFind(cl, Round(cl + cw) - 1)
					if (pc >= 0)
						{
						if (Abs(pc - (cl + cw / 2.0)) <= 0.01 * WindowWidth)
							one := true
						else
							SwMeasN--
						}
					if (one or SwMeasN >= 2)
						{
						SwWMeas := true
						SwLog("bar measured " . Round(cw))
						}
					}
				else
					SwMeasN := 0
				}
			else if (cw >= 0.97 * Wp)
				{
				SwWMeas := false
				SwMeasN := 0
				SwW := Wp
				}
			if (SwWMeas)
				{
				SwW := cw
				L := cl
				w := Round(cw)
				}
			else if (Abs(cw - SwW) <= 0.03 * SwW)
				{
				L := cl
				w := Round(cw)
				}
			}
		else
			{
		SwWRing.Push(cw)
		if (SwWRing.Length() > 7)
			SwWRing.RemoveAt(1)
		n := SwWRing.Length()
		if (n >= 3)
			{
			l3 := [SwWRing[n - 2], SwWRing[n - 1], SwWRing[n]]
			m3 := SwMedian(l3)
			mx := l3[1]
			mn := l3[1]
			for i, v in l3
				{
				if (v > mx)
					mx := v
				if (v < mn)
					mn := v
				}
			if (mx - mn <= 0.01 * mx and Abs(m3 - SwW) > 0.03 * SwW)
				{
				SwW := m3
				SwWRing := l3
				}
			else
				SwW := SwMedian(SwWRing)
			}
		else
			SwW := cw
		if (Abs(cw - SwW) <= 0.03 * SwW or (SwLastL >= 0 and Abs(cw - SwBarW) <= 0.06 * SwW))
			{
			L := cl
			w := Round(cw)
			}
			}
		if (!SwFrLearned)
			SwFrameLearn(yt, cl, cw)
		}
	if (L < 0 and SwW > 0)
		{
		wi := Round(SwW)
		if (SwFit(ra, rb, yt, yb, wi, fl))
			{
			L := fl
			w := wi
			}
		}
	if (L < 0)
		{
		if (SwFrMiss = 0 and now - SwFrMoveT >= 0.2 and Abs(SwFrTop - SwFrRef) <= 1 and now - SwLitRawT >= 0.8 and SwDarkTest())
			SwFrBad++
		SwBarHold := (SwFoundT and now - SwFoundT < 0.5 and now - SwLitRawT < 0.6 and SwFrMiss = 0)
		return
		}
	SwFrBad := 0
	if (SwFrH > 0)
		{
		SwFrOk := true
		SwCacheW := WindowWidth
		SwCacheH := WindowHeight
		SwCacheSB := SwSB
		SwCacheFrH := SwFrH
		SwCacheFrT := SwFrT
		}
	SwFound := true
	SwFoundT := now
	SwBarL := Round(FishBarLeft) + L
	SwBarW := w
	SwLastL := L
	SwLastC := SwBarL + w / 2.0
	SwPianoCheck()
}

SwFrameCov(y, xa, xb) {
	global pCaptureBits, CaptureW, CaptureH, SwPrmFr, SwPrmFrI, SwXBar, SwXBarN
	if (y < 0 or y >= CaptureH)
		return 0
	rr := []
	SwRuns(pCaptureBits + y * CaptureW * 4, xa, xb, SwPrmFr, SwPrmFrI, 3, rr)
	if (SwXBarN)
		SwRunsX(pCaptureBits + y * CaptureW * 4, xa, xb, &SwXBar, SwXBarN, 3, rr)
	c := 0
	for i, v in rr
		c += v[2] - v[1] + 1
	return c
}

SwFrameBot(ft, ByRef t0, ByRef t1, ByRef r0, ByRef r1) {
	global CaptureW, CaptureH, SwS, SwSX, SwSB, FishBarLeft, WindowWidth
	t0 := -1
	t1 := -1
	r0 := -1
	r1 := -1
	xa := Round(WindowWidth * 0.225) - Round(FishBarLeft)
	xb := Round(WindowWidth * 0.775) - Round(FishBarLeft)
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	thin := Round(8 * ((SwSB > SwSX) ? SwSB : SwSX))
	if (thin < 3)
		thin := 3
	tc := []
	ct := 0
	Loop % thin + 1
		{
		c := SwFrameCov(ft + A_Index - 1, xa, xb)
		tc.Push(c)
		if (c > ct)
			ct := c
		}
	if (ct < 0.08 * WindowWidth)
		return
	u0 := 0
	while (u0 <= thin and tc[u0 + 1] < 0.6 * ct)
		u0++
	u1 := u0
	while (u1 + 1 <= thin and tc[u1 + 2] >= 0.6 * ct)
		u1++
	ya := ft + Round(60 * ((SwS < SwSX) ? SwS : SwSX))
	yz := ft + Round(110 * ((SwS > SwSX) ? SwS : SwSX))
	if (ya < 0)
		ya := 0
	if (yz > CaptureH - 1)
		yz := CaptureH - 1
	best := 0
	q0 := -1
	q1 := -1
	s0 := -1
	pk := 0
	y := ya
	while (y <= yz + 1)
		{
		c := (y <= yz) ? SwFrameCov(y, xa, xb) : 0
		if (y <= yz and c >= 0.6 * ct)
			{
			if (s0 < 0)
				{
				s0 := y
				pk := 0
				}
			if (c > pk)
				pk := c
			}
		else if (s0 >= 0)
			{
			if (y <= yz and y - s0 <= thin and pk > best)
				{
				best := pk
				q0 := s0 - ft
				q1 := y - 1 - ft
				}
			s0 := -1
			}
		y++
		}
	if (q0 < 0)
		return
	t0 := u0
	t1 := u1
	r0 := q0
	r1 := q1
}

SwCleanFrame(ra, rb, yt, yb, ByRef cl, ByRef cw, now) {
	global pCaptureBits, CaptureW, SwS, SwSB, SwPhase, WindowWidth, SwPrmFr, SwWMeas, SwPostT, SwPitch
	cl := -1
	cw := 0
	if (!ra.Length() or !rb.Length())
		return false
	mn := 6 * SwSB
	a1 := -1
	b1 := -1
	for i, v in ra
		{
		if (v[2] - v[1] + 1 >= mn)
			{
			if (a1 < 0)
				a1 := v[1]
			b1 := v[2]
			}
		}
	a2 := -1
	b2 := -1
	for i, v in rb
		{
		if (v[2] - v[1] + 1 >= mn)
			{
			if (a2 < 0)
				a2 := v[1]
			b2 := v[2]
			}
		}
	if (a1 < 0 or a2 < 0)
		return false
	agree := 6 * SwSB
	if (SwWMeas or (SwPostT and now - SwPostT < 1.0))
		agree := 10 * SwSB
	if (Abs(a1 - a2) > agree or Abs(b1 - b2) > agree)
		return false
	w1 := b1 - a1 + 1
	if (w1 < 0.08 * WindowWidth or w1 > 0.5 * WindowWidth)
		return false
	m := Round(0.2 * SwPitch)
	if (SwInZone(a1, m) or SwInZone(b1, m) or SwInZone(a2, m) or SwInZone(b2, m))
		return false
	e1 := SwZoneLen(a1, b1)
	e2 := SwZoneLen(a2, b2)
	c1 := SwCover(ra, a1, b1)
	c2 := SwCover(rb, a2, b2)
	w2 := b2 - a2 + 1
	if ((c1 < 0.85 * w1 or c2 < 0.85 * w2) and (e1 > 0.7 * w1 or 0.15 * c1 + 0.85 * SwCoverX(ra, a1, b1) < 0.85 * (w1 - e1) or 0.15 * c2 + 0.85 * SwCoverX(rb, a2, b2) < 0.85 * (w2 - e2)))
		return false
	if (SwPhase and SwDarkTest())
		{
		g3 := Round(3 * SwSB)
		g9 := Round(9 * SwSB)
		for i, y in [yt, yb]
			{
			p := pCaptureBits + y * CaptureW * 4
			x := a1 - g9
			while (x <= a1 - g3)
				{
				if (x < 0 or SwLum(p + x * 4) >= 240)
					return false
				x++
				}
			x := b1 + g3
			while (x <= b1 + g9)
				{
				if (x >= CaptureW or SwLum(p + x * 4) >= 240)
					return false
				x++
				}
			}
		}
	cl := (a1 + a2) // 2
	cw := ((b1 - a1 + 1) + (b2 - a2 + 1)) / 2.0
	return true
}

SwFrameLearn(yt, cl, cw) {
	global pCaptureBits, CaptureW, SwFrLearned, SwFrR, SwFrG, SwFrB, SwPrmFr
	p := pCaptureBits + yt * CaptureW * 4
	n := 0
	r := 0
	g := 0
	b := 0
	Loop 32
		{
		x := Round(cl + cw * (A_Index - 0.5) / 32)
		if (x < 0 or x >= CaptureW)
			continue
		if (PcFind(p + x * 4, 1, 4, SwPrmFr) != 0)
			continue
		px := NumGet(p + x * 4, 0, "UInt")
		b += px & 0xFF
		g += (px >> 8) & 0xFF
		r += (px >> 16) & 0xFF
		n++
		}
	if (n < 12)
		return
	SwFrR := r // n
	SwFrG := g // n
	SwFrB := b // n
	SwSetFrame(SwFrR, SwFrG, SwFrB)
	SwFrLearned := true
	SwLog("frame " . SwFrR . "," . SwFrG . "," . SwFrB . " n=" . n)
}

SwFit(ra, rb, yt, yb, w, ByRef L) {
	global pCaptureBits, CaptureW, SwS, SwSB, SwLastL, WindowWidth, SwPrmBk, SwPrmBkI
	L := -1
	cands := []
	for i, rr in [ra, rb]
		{
		for j, v in rr
			{
			if (v[2] - v[1] + 1 < 6 * SwSB)
				continue
			cands.Push(v[1])
			cands.Push(v[2] - w + 1)
			}
		}
	if (!cands.Length())
		return false
	ka := []
	kb := []
	xa := 0
	xb := CaptureW - 1
	SwRuns(pCaptureBits + yt * CaptureW * 4, xa, xb, SwPrmBk, SwPrmBkI, 0, ka)
	SwRuns(pCaptureBits + yb * CaptureW * 4, xa, xb, SwPrmBk, SwPrmBkI, 0, kb)
	d := Round(0.04 * w)
	if (d < 4)
		d := 4
	lim := Round(0.1 * WindowWidth)
	best := -999999
	bestIn := 0
	bestEx := 0
	for i, c in cands
		{
		if (SwLastL >= 0 and Abs(c - SwLastL) > lim)
			continue
		inside := SwCoverX(ra, c, c + w - 1) + SwCoverX(rb, c, c + w - 1)
		ex := SwZoneLen(c, c + w - 1)
		outside := SwCoverX(ra, c - d, c - 1) + SwCoverX(ra, c + w, c + w + d - 1) + SwCoverX(rb, c - d, c - 1) + SwCoverX(rb, c + w, c + w + d - 1)
		dark := SwCover(ka, c, c + w - 1) + SwCover(kb, c, c + w - 1)
		sc := inside - outside - 5 * dark
		if (SwLastL >= 0)
			sc -= Abs(c - SwLastL) * 0.25
		if (sc > best)
			{
			best := sc
			L := c
			bestIn := inside
			bestEx := ex
			}
		}
	pl := (L < 0) ? 0 : SwCover(ra, L, L + w - 1) + SwCover(rb, L, L + w - 1)
	if (L < 0 or ((bestEx > 0.7 * w or 0.3 * pl + 0.7 * bestIn < 1.4 * (w - bestEx)) and pl < 1.4 * w))
		{
		L := -1
		return false
		}
	return true
}

SwPianoFind(xa, xb) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwPrmBk, SwPrmBkI
	yb := SwFrTop + Round(21 * SwSB)
	yu := SwFrTop + Round(13 * SwSB)
	if (yb >= CaptureH or yu < 0)
		return -1
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	rr := []
	SwRuns(pCaptureBits + yb * CaptureW * 4, xa, xb, SwPrmBk, SwPrmBkI, 0, rr)
	pu := pCaptureBits + yu * CaptureW * 4
	for i, v in rr
		{
		ln := v[2] - v[1] + 1
		if (ln < 40 * SwSB or ln > 62 * SwSB)
			continue
		bright := 0
		x := v[1]
		while (x <= v[2])
			{
			if (SwLum(pu + x * 4) >= 320)
				bright++
			x++
			}
		if (bright < 0.6 * ln)
			continue
		return (v[1] + v[2]) / 2.0
		}
	return -1
}

SwPianoCheck() {
	global SwBarL, SwBarW, SwPiano, SwPianoDis, SwWRing, SwW, FishBarLeft, WindowWidth, SwLastL, SwLastC
	SwPiano := -1
	xa := SwBarL - Round(FishBarLeft)
	pc := SwPianoFind(xa, xa + SwBarW - 1)
	if (pc < 0)
		return
	SwPiano := Round(FishBarLeft) + pc
	c := SwBarL + SwBarW / 2.0
	if (Abs(c - SwPiano) > 0.015 * WindowWidth)
		{
		SwPianoDis++
		if (SwPianoDis >= 3)
			{
			SwLog("piano disagrees " . Round(c) . " vs " . Round(SwPiano) . " w=" . Round(SwW))
			SwWRing := []
			SwBarL := Round(SwPiano - SwBarW / 2.0)
			SwLastL := SwBarL - Round(FishBarLeft)
			SwLastC := SwBarL + SwBarW / 2.0
			SwPianoDis := 0
			}
		}
	else
		SwPianoDis := 0
}

SwFishScan(now) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwFishX, SwFishAt, SwFishLast, FishBarLeft, WindowWidth, SwPrmCap, SwPrmCapI, SwPrmHd, SwPrmHdI, SwFishHeld
	global SwFrMiss, SwFound, SwBarL, SwBarW
	global SwXCap, SwXCapN, SwXHd, SwXHdN
	SwFishX := -1
	yc := SwFrTop - Round(5 * SwSB)
	yh := SwFrTop - Round(41 * SwSB)
	if (yh < 0 or yc >= CaptureH)
		return
	xa := Round(WindowWidth * 0.225) - Round(FishBarLeft)
	xb := Round(WindowWidth * 0.775) - Round(FishBarLeft)
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	rc := []
	rh := []
	SwRuns(pCaptureBits + yc * CaptureW * 4, xa, xb, SwPrmCap, SwPrmCapI, 0, rc)
	if (SwXCapN)
		SwRunsX(pCaptureBits + yc * CaptureW * 4, xa, xb, &SwXCap, SwXCapN, 0, rc)
	SwRuns(pCaptureBits + yh * CaptureW * 4, xa, xb, SwPrmHd, SwPrmHdI, 0, rh)
	if (SwXHdN)
		SwRunsX(pCaptureBits + yh * CaptureW * 4, xa, xb, &SwXHd, SwXHdN, 0, rh)
	caps := []
	for i, v in rc
		{
		ln := v[2] - v[1] + 1
		if (ln >= Floor(6 * SwSB) and ln <= Round(20 * SwSB))
			caps.Push((v[1] + v[2]) / 2.0)
		}
	heads := []
	for i, v in rh
		{
		ln := v[2] - v[1] + 1
		if (ln >= Floor(16 * SwSB) and ln <= Round(38 * SwSB))
			heads.Push((v[1] + v[2]) / 2.0)
		}
	fx := -1
	for i, c in caps
		{
		for j, h in heads
			{
			if (c - h >= -3 * SwSB and c - h <= 16 * SwSB)
				{
				fx := c
				break
				}
			}
		if (fx >= 0)
			break
		}
	if (fx < 0 and caps.Length() = 1)
		fx := caps[1]
	if (fx < 0 and heads.Length() = 1 and SwFishLast >= 0 and now - SwFishAt < 0.2)
		{
		h := heads[1] + 7.5 * SwSB
		if (Abs(Round(FishBarLeft) + h - SwFishLast) <= 0.05 * WindowWidth)
			fx := h
		}
	if (fx < 0)
		{
		held := (SwFishLast >= 0 and now - SwFishAt < 0.6 and SwFrMiss = 0 and SwFound and SwFishLast >= SwBarL + 0.15 * SwBarW
			and SwFishLast <= SwBarL + 0.85 * SwBarW and SwGlowNear(SwFishLast - Round(FishBarLeft), 1.1, 0.7, now))
		if (held)
			{
			SwFishX := SwFishLast
			if (!SwFishHeld)
				SwLog("fish held at " . Round(SwFishLast))
			}
		SwFishHeld := held
		return
		}
	SwFishHeld := false
	SwFishX := Round(FishBarLeft) + fx
	SwFishLast := SwFishX
	SwFishAt := now
}

SwDarkTest() {
	global pCaptureBits, CaptureW, SwS, SwSB, SwFrTop, FishBarLeft, WindowWidth, SwZL
	y := SwFrTop - Round(12 * SwSB)
	if (y < 0)
		return false
	n := 0
	d := 0
	p := pCaptureBits + y * CaptureW * 4
	Loop 24
		{
		x := Round(WindowWidth * (0.225 + 0.55 * (A_Index - 0.5) / 24)) - Round(FishBarLeft)
		if (x < 0 or x >= CaptureW or SwInZone(x, 0))
			continue
		px := NumGet(p + x * 4, 0, "UInt")
		b := px & 0xFF
		g := (px >> 8) & 0xFF
		r := (px >> 16) & 0xFF
		mx := (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
		n++
		if (mx < 50)
			d++
		}
	return (n >= (SwZL.Length() ? 8 : 12) and d >= 0.85 * n)
}

SwGradLearn() {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwCleanL, SwCleanW, SwGrad, SwGradOk, SwDarkR, SwDarkG, SwDarkB
	if (SwCleanL < 0 or SwCleanW < 20)
		return
	y := SwFrTop + Round(44 * SwSB)
	if (y >= CaptureH)
		return
	p := pCaptureBits + y * CaptureW * 4
	c := SwCleanL + SwCleanW / 2.0
	last := -1
	Loop 64
		{
		x := Round(SwCleanL + SwCleanW * (A_Index - 0.5) / 64)
		if (x < 0 or x >= CaptureW)
			continue
		if (Abs(x - c) <= 32 * SwSB)
			{
			if (last >= 0)
				{
				NumPut(NumGet(SwGrad, last * 3, "UChar"), SwGrad, (A_Index - 1) * 3, "UChar")
				NumPut(NumGet(SwGrad, last * 3 + 1, "UChar"), SwGrad, (A_Index - 1) * 3 + 1, "UChar")
				NumPut(NumGet(SwGrad, last * 3 + 2, "UChar"), SwGrad, (A_Index - 1) * 3 + 2, "UChar")
				}
			continue
			}
		px := NumGet(p + x * 4, 0, "UInt")
		NumPut(px & 0xFF, SwGrad, (A_Index - 1) * 3, "UChar")
		NumPut((px >> 8) & 0xFF, SwGrad, (A_Index - 1) * 3 + 1, "UChar")
		NumPut((px >> 16) & 0xFF, SwGrad, (A_Index - 1) * 3 + 2, "UChar")
		last := A_Index - 1
		}
	n := 0
	r := 0
	g := 0
	b := 0
	for i, x in [SwCleanL - Round(9 * SwSB), SwCleanL - Round(6 * SwSB), SwCleanL - Round(3 * SwSB), SwCleanL + Round(SwCleanW) + Round(3 * SwSB), SwCleanL + Round(SwCleanW) + Round(6 * SwSB), SwCleanL + Round(SwCleanW) + Round(9 * SwSB)]
		{
		if (x < 0 or x >= CaptureW)
			continue
		px := NumGet(p + x * 4, 0, "UInt")
		if ((px & 0xFF) >= 60 or ((px >> 8) & 0xFF) >= 60 or ((px >> 16) & 0xFF) >= 60)
			continue
		b += px & 0xFF
		g += (px >> 8) & 0xFF
		r += (px >> 16) & 0xFF
		n++
		}
	if (n >= 3)
		{
		SwDarkR := r // n
		SwDarkG := g // n
		SwDarkB := b // n
		}
	SwGradOk := true
	SwLog("gradient learned L=" . SwCleanL . " w=" . Round(SwCleanW) . " dark=" . SwDarkR . "," . SwDarkG . "," . SwDarkB)
}

SwSlotStrokes(k) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwPitch, FishBarLeft, SwPrmCore, SwPrmCoreI
	cx := Round(SwSlotX(k)) - Round(FishBarLeft)
	half := Round(0.45 * SwPitch)
	a := cx - half
	b := cx + half
	if (a < 0)
		a := 0
	if (b > CaptureW - 1)
		b := CaptureW - 1
	if (b - a < 8)
		return 0
	lo := Round(4 * SwSB)
	if (lo < 3)
		lo := 3
	hi := Round(20 * SwSB)
	gap := Round(2 * SwSB)
	if (gap < 2)
		gap := 2
	cnt := 0
	marg := (SwSB < 0.8) ? 80 : 120
	for i, dy in [20, 32, 44, 56, 68]
		{
		y := SwFrTop + Round(dy * SwSB)
		if (y < 0 or y >= CaptureH)
			continue
		p := pCaptureBits + y * CaptureW * 4
		rr := []
		SwRuns(p, a, b, SwPrmCore, SwPrmCoreI, 0, rr)
		for j, v in rr
			{
			ln := v[2] - v[1] + 1
			if (ln < lo or ln > hi)
				continue
			cl := 0
			x := v[1]
			while (x <= v[2])
				{
				cl += SwLum(p + x * 4)
				x++
				}
			cl := cl // ln
			thr := cl + marg
			if (thr > 640)
				thr := 640
			okl := false
			x := v[1] - gap
			while (x < v[1])
				{
				if (x >= a and SwLum(p + x * 4) >= thr)
					okl := true
				x++
				}
			okr := false
			x := v[2] + 1
			while (x <= v[2] + gap)
				{
				if (x <= b and SwLum(p + x * 4) >= thr)
					okr := true
				x++
				}
			if (okl and okr)
				cnt++
			}
		}
	return cnt
}

SwSlotWhite(k) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwPitch, FishBarLeft, SwPrmWh, SwPrmWhI
	cx := Round(SwSlotX(k)) - Round(FishBarLeft)
	half := Round(0.45 * SwPitch)
	a := cx - half
	b := cx + half
	if (a < 0)
		a := 0
	if (b > CaptureW - 1)
		b := CaptureW - 1
	cnt := 0
	for i, dy in [24, 44, 64]
		{
		y := SwFrTop + Round(dy * SwSB)
		if (y < 0 or y >= CaptureH)
			continue
		rr := []
		SwRuns(pCaptureBits + y * CaptureW * 4, a, b, SwPrmWh, SwPrmWhI, 0, rr)
		for j, v in rr
			{
			ln := v[2] - v[1] + 1
			if (ln >= 3 * SwSB and ln <= 40 * SwSB)
				cnt++
			}
		}
	return (cnt >= 2)
}

SwSlotsScan(now, held := false) {
	global SwSlotSt, SwSlotFirst, SwSlotHits, SwSlotLvl, SwSlotGone, SwOrder, SwK0, SwLit, SwClicks, SwStop, SwStopWhy, SwTie, SwLastOnset, SwZ
	global SwSlotBlind, SwFishX, SwSB, SwMaxSigns
	Loop 12
		{
		k := A_Index
		st := SwSlotSt[k]
		if (st >= 2)
			continue
		c := SwSlotStrokes(k)
		if (c >= 1)
			{
			SwSlotGone[k] := 0
			if (st = 0)
				{
				SwSlotSt[k] := 1
				SwSlotFirst[k] := now
				SwSlotLvl[k] := c
				SwSlotHits[k] := (c >= 2) ? 1 : 0
				}
			else
				SwSlotHits[k] := (c >= 2) ? SwSlotHits[k] + 1 : SwSlotHits[k]
			if (SwSlotSt[k] = 1 and (SwSlotHits[k] >= (SwMaxSigns ? 1 : 2) or c >= 4))
				SwAssign(k, now)
			}
		else if (st = 1 and !held)
			{
			if (!SwSlotGone[k])
				SwSlotGone[k] := now
			else if (now - SwSlotGone[k] > 0.3)
				{
				SwSlotSt[k] := 0
				SwSlotHits[k] := 0
				SwSlotGone[k] := 0
				}
			}
		else if (st = 0 and !held and (SwFishX < 0 or Abs(SwFishX - SwSlotX(k)) >= 40 * SwSB))
			SwSlotBlind[k] := now
		}
}

SwAssign(k, now) {
	global SwMaxSigns, SwClickAt, SwClickLit, SwBurstN
	global SwSlotSt, SwSlotFirst, SwSlotLvl, SwOrder, SwK0, SwLit, SwClicks, SwStop, SwStopWhy, SwTie, SwLastOnset, SwZ, SwPhaseT, SwStarStableT, SwLitRaw, SwLitRawT, SwTieWas, SwSlotBlind
	SwSlotSt[k] := 2
	if (SwK0 < 0 and now - SwStarStableT >= SwSec(SwMaxSigns ? 0 : 0.1) and SwLit = SwLitRaw and now - SwLitRawT >= SwSec(SwMaxSigns ? 0.05 : 0.3))
		SwK0 := SwLit
	pos := SwOrder.Length() + 1
	i := SwOrder.Length()
	while (i >= 1)
		{
		o := SwOrder[i]
		if (SwSlotFirst[o] > SwSlotFirst[k] or (SwSlotFirst[o] = SwSlotFirst[k] and SwSlotLvl[o] < SwSlotLvl[k]))
			pos := i
		else
			break
		i--
		}
	; counted late (it was half hidden): the signs whose stars already lit stay before it, so it goes after
	; them, marked as a tie so its shape decides. Counted by lit stars, not by clicks - a click that never
	; lit a star (failed, retried) does not hold a place. A click still waiting for its star does.
	late := false
	done := (SwK0 >= 0) ? SwLit - SwK0 : 0
	if (SwClickAt and SwK0 >= 0 and SwClickLit - SwK0 + SwBurstN > done)
		done := SwClickLit - SwK0 + SwBurstN
	if (done > 0 and pos <= done)
		{
		pos := done + 1
		if (pos > SwOrder.Length() + 1)
			pos := SwOrder.Length() + 1
		late := true
		SwLog("late onset slot " . k . " moved to " . pos)
		}
	SwOrder.InsertAt(pos, k)
	if (late)
		{
		SwTie[k] := 1
		if (pos < SwOrder.Length())
			SwTie[SwOrder[pos + 1]] := 1
		}
	if (pos > 1 and Abs(SwSlotFirst[SwOrder[pos - 1]] - SwSlotFirst[k]) < 0.15)
		{
		SwTie[k] := 1
		SwTie[SwOrder[pos - 1]] := 1
		}
	if (pos < SwOrder.Length() and Abs(SwSlotFirst[SwOrder[pos + 1]] - SwSlotFirst[k]) < 0.15)
		{
		SwTie[k] := 1
		SwTie[SwOrder[pos + 1]] := 1
		}
	b := SwSlotBlind[k]
	if (b < SwPhaseT)
		b := SwPhaseT
	Loop % pos - 1
		{
		o := SwOrder[A_Index]
		if (o != k and SwSlotFirst[o] >= b - 0.05)
			{
			SwTie[o] := 1
			SwTie[k] := 1
			}
		}
	Loop % SwOrder.Length() - pos
		{
		o := SwOrder[pos + A_Index]
		bo := SwSlotBlind[o]
		if (bo < SwPhaseT)
			bo := SwPhaseT
		if (SwSlotFirst[k] >= bo - 0.05)
			{
			SwTie[o] := 1
			SwTie[k] := 1
			}
		}
	Loop 12
		{
		if (SwTie[A_Index] = 1)
			SwTieWas[A_Index] := 1
		}
	SwLastOnset := now
	SwLog("onset slot " . k . " rank " . pos . " t+" . Round((now - SwPhaseT) * 1000) . " lvl " . SwSlotLvl[k] . (SwTie[k] ? " tie" : ""))
}

; how many signs "Wait for signs" waits for: the number set (12 = all), never more than are left this round
SwWaitNeed() {
	global SwWaitN, SwK0
	n := SwWaitN
	if n is not number
		n := 12
	n := Round(n)
	if (n < 1)
		n := 1
	rem := 12 - ((SwK0 < 0) ? 0 : SwK0)
	return (n < rem) ? n : rem
}

SwZodiac(i) {
	global SwZ
	return SwZ[Mod(i, 12) + 1]
}

SwSoftFail(why, now) {
	global SwRetryFails, SwFailN, SwFailAt, SwClickAt, SwRetry, SwPurpleN, SwClickSlot, SwMaxSigns, SwRetryK, SwLit, SwK0, SwOrder
	global SwFailLit, SwFailSlot, SwFailWhite
	if (!SwRetryFails or SwFailN >= 3)
		return false
	SwFailLit := SwLit
	SwFailSlot := SwClickSlot
	SwFailWhite := (why = "white") ? SwClickSlot : 0
	ti := SwLit - SwK0 + 1
	SwRetryK := (SwK0 >= 0 and ti >= 1 and ti <= SwOrder.Length()) ? SwOrder[ti] : SwClickSlot
	; the sign went white but no star lit - it was probably the wrong sign, so look for the right one first
	if (why = "white" and SwK0 >= 0 and ti >= 1)
		{
		fk := SwFindSign(ti, Mod(SwK0 + ti - 1, 12), SwClickSlot, true)
		if (fk)
			SwRetryK := fk
		}
	; a sign that went white is used up - never re-click it; when the retry is due, look for the right one
	if (SwFailWhite and SwRetryK = SwFailWhite)
		SwRetryK := -1
	SwFailN := SwFailN + 1
	SwClickAt := 0
	SwRetry := 0
	SwPurpleN := 0
	SwFailAt := now + (SwMaxSigns ? TA("swretrymax", 150) : TA("swretry", 250)) / 1000.0
	SwLog("retry after " . why . " slot " . SwClickSlot . " (" . SwFailN . "/3)")
	return true
}

; the sign for zodiac z among the signs on the bar that were not clicked yet - for when the onset
; order is wrong (signs that showed up together). Moves it to place i in the click order.
SwFindSign(i, z, excl := 0, force := false) {
	global SwSlotSt, SwOrder, SwTie, SwFindT
	if (!SwTplSumFn() or i < 1 or i > SwOrder.Length() + 1)
		return 0
	now := SwNow()
	; reading every sign's shape is slow - at most every 120 ms
	if (!force and SwFindT and now - SwFindT < 0.12)
		return 0
	SwFindT := now
	best := 0
	bestS := -9
	secondS := -9
	Loop 12
		{
		kk := A_Index
		st := SwSlotSt[kk]
		if (kk = excl or (st != 1 and st != 2))
			continue
		pos := 0
		Loop % SwOrder.Length()
			{
			if (SwOrder[A_Index] = kk)
				{
				pos := A_Index
				break
				}
			}
		if (pos and pos < i)
			continue
		if (SwSlotWhite(kk))
			continue
		tdZ := -1
		tdS := -9
		sc := SwTplBest2(kk, z, tdZ, tdS)
		if (sc < 0.4 or tdZ != z)
			continue
		if (sc > bestS)
			{
			secondS := bestS
			bestS := sc
			best := kk
			}
		else if (sc > secondS)
			secondS := sc
		}
	if (!best or bestS - secondS < 0.08)
		return 0
	Loop % SwOrder.Length()
		{
		if (SwOrder[A_Index] = best)
			{
			SwOrder.RemoveAt(A_Index)
			break
			}
		}
	SwOrder.InsertAt(i, best)
	SwSlotSt[best] := 2
	SwTie[best] := 0
	SwLog("found slot " . best . " for " . SwZodiac(z) . " (" . Round(bestS, 3) . " vs " . Round(secondS, 3) . ")")
	return best
}

; Retry failed clicks: a sign that looks like a different zodiac is never clicked blindly - find the
; right sign, give the shape a moment to read clean (the fish or bar can cover it), otherwise stop
SwVetoWait(i, k, z, now) {
	global SwOverK, SwOverT, SwOverL, SwStop, SwStopWhy
	if (SwRecover(i, z))
		return
	if (SwFindSign(i, z, k))
		return
	if (SwOverK != k * 16 + z or now - SwOverL > 0.15)
		{
		SwOverK := k * 16 + z
		SwOverT := now
		}
	SwOverL := now
	if (now - SwOverT < 0.6)
		return
	SwStop := true
	SwStopWhy := "shape veto " . SwZodiac(z) . " slot " . k . " (right sign not found)"
	SwLog("stop: " . SwStopWhy)
}

; true when sign k clearly reads as a later zodiac than z (the one that is due)
SwLooksOther(k, z) {
	tdZ := -1
	tdS := -9
	sc := SwTplBest2(k, z, tdZ, tdS)
	return (tdS >= 0.5 and tdZ != z and tdS >= sc + 0.2)
}

; a queued retry only clicks when it is still needed and still aimed at the right sign: a star that lit late
; means the first click worked (nothing is re-clicked), and a used-up (white) sign or one that reads as a
; different zodiac is swapped for the sign that matches - or nothing is clicked at all
SwRetryFire() {
	global SwRetryK, SwFailAt, SwFailLit, SwFailSlot, SwFailWhite, SwLit, SwLitRaw, SwLitRawT, SwK0, SwOrder, SwSlotSt
	global SwFailN, SwStop, SwStopWhy
	now := SwNow()
	if (now < SwFailAt)
		return
	if (SwLit != SwLitRaw or now - SwLitRawT < 0.08)
		return
	if (SwLit < SwFailLit)
		{
		; a dropped count is nearly always a misread - wait for it, then leave it to the normal checks
		if (now - SwLitRawT < 0.4)
			return
		SwRetryK := 0
		return
		}
	if (SwLit > SwFailLit)
		{
		if (SwK0 >= 0)
			{
			bi := SwFailLit - SwK0 + 1
			; the click that "failed" is the one that worked - put it back in its place if the order was changed
			if (SwFailSlot and bi >= 1 and bi <= SwOrder.Length() and SwOrder[bi] != SwFailSlot)
				{
				Loop % SwOrder.Length()
					{
					if (SwOrder[A_Index] = SwFailSlot)
						{
						SwOrder.RemoveAt(A_Index)
						break
						}
					}
				SwOrder.InsertAt(bi, SwFailSlot)
				}
			Loop % SwLit - SwFailLit
				{
				bj := bi + A_Index - 1
				if (bj >= 1 and bj <= SwOrder.Length())
					{
					SwSlotSt[SwOrder[bj]] := 3
					SwMemMark(SwOrder[bj])
					}
				}
			if (SwLit >= 12)
				SwMemReset()
			}
		SwLog("retry cancelled - the star lit late " . SwFailLit . "->" . SwLit)
		SwRetryK := 0
		SwFailN := 0
		SwFailAt := 0
		return
		}
	ti := SwLit - SwK0 + 1
	z := Mod(SwK0 + ti - 1, 12)
	k := SwRetryK
	if (k > 0 and (SwSlotSt[k] = 3 or SwSlotWhite(k)))
		{
		SwLog("retry target slot " . k . " is used up - looking for " . SwZodiac(z))
		k := 0
		}
	else if (k > 0)
		{
		; the failed sign is suspect: whichever sign reads most like the due zodiac gets the retry
		pk := SwPickSign(ti, k, z, 0)
		if (pk = k and SwLooksOther(k, z))
			pk := 0
		k := pk
		}
	if (k <= 0)
		k := SwFindSign(ti, z, SwFailWhite, true)
	if (!k)
		{
		; the fish or the bar can hide the right sign for a moment - keep looking a little
		if (now - SwFailAt < 0.6)
			return
		SwRetryK := 0
		SwStop := true
		SwStopWhy := "retry: no sign that reads as " . SwZodiac(z)
		SwLog("stop: " . SwStopWhy)
		return
		}
	SwRetryK := 0
	SwRetryClick(k)
}

; which sign to click for zodiac z at place i: k - unless k reads more like another zodiac (by at least
; `need`) and a sign not clicked yet reads as z; then that one (moved to place i in the click order).
; need 0.1 before a first click (only a clear mix-up switches), 0 after a click did not take (k is suspect)
SwPickSign(i, k, z, need) {
	tdZ := -1
	tdS := -9
	sc := SwTplBest2(k, z, tdZ, tdS)
	if (sc <= -9 or tdZ = z or tdS < sc + need)
		return k
	fk := SwFindSign(i, z, k, true)
	if (!fk)
		return k
	SwLog("slot " . k . " reads as " . SwZodiac(tdZ) . " - slot " . fk . " for " . SwZodiac(z))
	return fk
}

; the sign to press again after a click did not take: the one that reads most like the due zodiac - never the
; same one again when it clearly reads as another zodiac (0 = do not click)
SwPurpleTarget() {
	global SwClickSlot, SwClickLit, SwK0
	z := Mod(SwClickLit, 12)
	ti := SwClickLit - SwK0 + 1
	if (SwK0 < 0 or ti < 1)
		return SwClickSlot
	rk := SwPickSign(ti, SwClickSlot, z, 0)
	if (rk = SwClickSlot and SwLooksOther(SwClickSlot, z))
		{
		SwLog("re-click slot " . SwClickSlot . " is not " . SwZodiac(z) . " - none found")
		return 0
		}
	return rk
}

SwRetryClick(k) {
	global RobloxHwnd, PrecisionDown, PrecisionUpAt, SwFishX, SwSB, SwFrTop, FishBarTop, LookDownX, LookDownY
	global SwClickAt, SwClickLit, SwClickSlot, SwLastClick, SwLastStep, SwClickTook, SwLit, SwBurstN, SwPreK, SwFailN
	if (!RobloxHwnd)
		return false
	t0 := SwNow()
	if (!WinActive("ahk_id " . RobloxHwnd))
		{
		WinActivate, ahk_id %RobloxHwnd%
		PreciseSleep(30)
		}
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		}
	SwPreK := 0
	PreciseSleep(30)
	VarSetCapacity(pt, 8, 0)
	NumPut(Round(LookDownX), pt, 0, "Int")
	NumPut(Round(LookDownY), pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	nx := NumGet(pt, 0, "Int")
	ny := NumGet(pt, 4, "Int")
	cx := Round(SwSlotX(k))
	if (Abs(SwFishX - cx) < 20 * SwSB)
		cx := cx + ((SwFishX >= cx) ? -Round(22 * SwSB) : Round(22 * SwSB))
	cy := Round(FishBarTop) + SwFrTop + Round(44 * SwSB)
	NumPut(cx, pt, 0, "Int")
	NumPut(cy, pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	sx := NumGet(pt, 0, "Int")
	sy := NumGet(pt, 4, "Int")
	CoordMode, Mouse, Screen
	MouseMove, %nx%, %ny%, 0
	PreciseSleep(TA("swrcneutral", 40))
	MouseMove, %sx%, %sy%, 0
	PreciseSleep(TA("swrchover", 10))
	MouseMove, % sx + 1, % sy, 0
	PreciseSleep(TA("swrcwait", 20))
	send {lbutton down}
	PreciseSleep(TA("swrchold", 80))
	send {lbutton up}
	PreciseSleep(30)
	MouseMove, %nx%, %ny%, 0
	CoordMode, Mouse, Client
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	SwClickAt := SwNow()
	SwClickTook := SwClickAt - t0
	SwClickLit := SwLit
	SwClickSlot := k
	SwBurstN := 1
	SwLastClick := SwClickAt
	SwLastStep := SwClickAt
	SwLog("forced retry click slot " . k . " (" . SwFailN . "/3)")
	return true
}

SwMemReset() {
	global SwMem, SwMemN, SwGuessTried, SwGuessDone
	SwMem := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwMemN := 0
	SwGuessTried := {}
	SwGuessDone := false
}

SwMemMark(k) {
	global SwMem, SwMemN
	if (!IsObject(SwMem))
		SwMemReset()
	if (k < 1 or k > 12 or SwMem[k])
		return
	SwMem[k] := 1
	SwMemN := SwMemN + 1
	if (SwMemN >= 12)
		SwMemReset()
}

SwGuessN() {
	global SwGuessLastN
	n := SwGuessLastN
	if n is not number
		return 3
	n := Round(n)
	return (n < 1) ? 1 : ((n > 11) ? 11 : n)
}

SwGuessReady() {
	global SwGuessLit, SwGuessUnlit
	lc := SwGuessLit
	uc := SwGuessUnlit
	if lc is not number
		return false
	if uc is not number
		return false
	return (lc >= 0 and uc >= 0 and SwGuessParse())
}

SwLastOnly() {
	global SwSlotSt, SwClickAt, SwClickLit, SwClickSlot, SwBurstN, SwLastClick, SwLastStep, SwClickTook, SwRetryK
	global PrecisionDown, PrecisionUpAt, RobloxHwnd, LookDownX, LookDownY, SwPreK
	if (SwClickAt or SwRetryK or !RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return false
	k := 0
	c := 0
	Loop 12
		{
		if (SwSlotSt[A_Index] != 3)
			{
			c++
			k := A_Index
			}
		}
	if (c != 1)
		return false
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		}
	SwPreK := 0
	t0 := SwNow()
	SwGuessClick(k)
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	SwClickAt := SwNow()
	SwClickTook := SwClickAt - t0
	SwClickLit := 11
	SwClickSlot := k
	SwBurstN := 1
	SwLastClick := SwClickAt
	SwLastStep := SwClickAt
	SwLog("last slot " . k . " clicked by elimination")
	return true
}

SwGuessParse() {
	global SwGuessPts, SwGuessP, SwGuessPtsC
	if (SwGuessPts = SwGuessPtsC and IsObject(SwGuessP) and SwGuessP.Length() = 12)
		return true
	SwGuessPtsC := SwGuessPts
	SwGuessP := []
	Loop, Parse, SwGuessPts, |
		{
		xy := StrSplit(A_LoopField, ",")
		if (xy.Length() = 2)
			SwGuessP.Push([Round(xy[1]), Round(xy[2])])
		}
	return (SwGuessP.Length() = 12)
}

SwGuessStars() {
	global RobloxHwnd, SwGuessP, SwGuessLit, SwGuessUnlit, SwGuessState
	static hdcM := 0, hbm := 0, pBits := 0, bw := 0, bh := 0
	lc := SwGuessLit
	uc := SwGuessUnlit
	if lc is not number
		return -1
	if uc is not number
		return -1
	if (!RobloxHwnd or lc < 0 or uc < 0 or !SwGuessParse())
		return -1
	x0 := 99999, y0 := 99999, x1 := -99999, y1 := -99999
	for i, pt in SwGuessP
		{
		x0 := (pt[1] < x0) ? pt[1] : x0
		y0 := (pt[2] < y0) ? pt[2] : y0
		x1 := (pt[1] > x1) ? pt[1] : x1
		y1 := (pt[2] > y1) ? pt[2] : y1
		}
	x0 -= 1
	y0 -= 1
	w := x1 - x0 + 2
	h := y1 - y0 + 2
	if (w != bw or h != bh or !hdcM)
		{
		if (hdcM)
			{
			DllCall("DeleteObject", "Ptr", hbm)
			DllCall("DeleteDC", "Ptr", hdcM)
			}
		hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
		hdcM := DllCall("CreateCompatibleDC", "Ptr", hdcS, "Ptr")
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt")
		NumPut(w, bi, 4, "Int")
		NumPut(-h, bi, 8, "Int")
		NumPut(1, bi, 12, "UShort")
		NumPut(32, bi, 14, "UShort")
		hbm := DllCall("CreateDIBSection", "Ptr", hdcM, "Ptr", &bi, "UInt", 0, "Ptr*", pBits, "Ptr", 0, "UInt", 0, "Ptr")
		if (!hbm)
			{
			DllCall("DeleteDC", "Ptr", hdcM)
			hdcM := 0
			return -1
			}
		DllCall("SelectObject", "Ptr", hdcM, "Ptr", hbm)
		bw := w
		bh := h
		}
	RobloxClientRect(RobloxHwnd, wx, wy)
	hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("BitBlt", "Ptr", hdcM, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcS, "Int", wx + x0, "Int", wy + y0, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
	lr := (lc >> 16) & 0xFF, lg := (lc >> 8) & 0xFF, lb := lc & 0xFF
	ur := (uc >> 16) & 0xFF, ug := (uc >> 8) & 0xFF, ub := uc & 0xFF
	SwGuessState := []
	n := 0
	run := true
	for i, pt in SwGuessP
		{
		cx := pt[1] - x0
		cy := pt[2] - y0
		r := 0, g := 0, b := 0, c := 0
		Loop 3
			{
			yy := cy + A_Index - 2
			if (yy < 0 or yy >= h)
				continue
			Loop 3
				{
				xx := cx + A_Index - 2
				if (xx < 0 or xx >= w)
					continue
				px := NumGet(pBits + 0, (yy * w + xx) * 4, "UInt")
				b += px & 0xFF
				g += (px >> 8) & 0xFF
				r += (px >> 16) & 0xFF
				c++
				}
			}
		if (!c)
			c := 1
		r := r / c, g := g / c, b := b / c
		dl := Abs(r - lr) + Abs(g - lg) + Abs(b - lb)
		du := Abs(r - ur) + Abs(g - ug) + Abs(b - ub)
		on := (dl < du)
		SwGuessState[i] := on
		if (run and on)
			n++
		else
			run := false
		}
	return n
}

SwGuessPick(lit) {
	global SwSlotSt, SwGuessTried, SwOrder, SwK0
	t := SwGuessTried[lit]
	all := []
	c := []
	Loop 12
		{
		k := A_Index
		if (SwSlotSt[k] = 3)
			continue
		all.Push(k)
		if (!t[k])
			c.Push(k)
		}
	if (c.Length() <= 1)
		return c.Length() ? c[1] : 0
	r := 12 - lit
	if (r > 3)
		r := 3
	if (r > all.Length())
		r := all.Length()
	sc := {}
	for i, k in all
		{
		pos := 0
		Loop % SwOrder.Length()
			{
			if (SwOrder[A_Index] = k)
				pos := A_Index
			}
		row := []
		Loop % r
			{
			j := A_Index - 1
			tdZ := -1
			tdS := -9
			v := SwTplBest2(k, Mod(lit + j, 12), tdZ, tdS)
			if (v < -1)
				v := 0
			if (tdS >= 0.5 and tdZ != Mod(lit + j, 12) and tdS >= v + 0.2)
				v -= 0.3
			if (SwK0 >= 0 and pos and SwK0 + pos - 1 = lit + j)
				v += 0.35
			row.Push(v)
			}
		sc[k] := row
		}
	best := -999
	bestK := c[1]
	for i, k in c
		{
		used := {}
		used[k] := 1
		v := sc[k][1] + SwGuessRest(all, sc, r, 2, used)
		if (v > best)
			{
			best := v
			bestK := k
			}
		}
	return bestK
}

SwGuessRest(all, sc, r, j, used) {
	if (j > r)
		return 0
	best := -999
	for i, k in all
		{
		if (used[k])
			continue
		used[k] := 1
		v := sc[k][j] + SwGuessRest(all, sc, r, j + 1, used)
		used.Delete(k)
		if (v > best)
			best := v
		}
	return (best = -999) ? 0 : best
}

SwGuessClick(k) {
	global RobloxHwnd, SwFishX, SwSB, SwFrTop, FishBarTop
	cx := Round(SwSlotX(k))
	if (Abs(SwFishX - cx) < 20 * SwSB)
		cx := cx + ((SwFishX >= cx) ? -Round(22 * SwSB) : Round(22 * SwSB))
	cy := Round(FishBarTop) + SwFrTop + Round(44 * SwSB)
	VarSetCapacity(pt, 8, 0)
	NumPut(cx, pt, 0, "Int")
	NumPut(cy, pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	sx := NumGet(pt, 0, "Int")
	sy := NumGet(pt, 4, "Int")
	CoordMode, Mouse, Screen
	MouseMove, %sx%, %sy%, 0
	PreciseSleep(TA("swgchover", 8))
	MouseMove, % sx + 1, % sy, 0
	PreciseSleep(TA("swgcwait", 8))
	send {lbutton down}
	PreciseSleep(TA("swgchold", 25))
	send {lbutton up}
	CoordMode, Mouse, Client
}

SwGuessRun(lit) {
	global RobloxHwnd, MacroRunning, PrecisionDown, PrecisionUpAt, LookDownX, LookDownY
	global SwSlotSt, SwGuessTried, SwGuessDone, SwGuessWait, SwGuessMsg, SwClickAt, SwRetryK, SwLastStep, SwLastClick, SwStop, SwStopWhy, SwPreK, SwFailN
	if (!RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		}
	SwPreK := 0
	SwRetryK := 0
	SwClickAt := 0
	wait := SwGuessWait
	if wait is not number
		wait := 100
	wait := (wait < 20) ? 20 : wait
	low := 12 - SwGuessN()
	passes := {}
	tries := 0
	log := ""
	while (MacroRunning and lit >= low and lit < 12 and tries < 24)
		{
		if (!IsObject(SwGuessTried[lit]))
			SwGuessTried[lit] := {}
		k := SwGuessPick(lit)
		if (!k)
			{
			if (passes[lit] >= 1)
				{
				SwGuessDone := true
				SwStop := true
				SwStopWhy := "auto retry ran out of signs"
				break
				}
			passes[lit] := 1
			SwGuessTried[lit] := {}
			continue
			}
		tries++
		SwGuessClick(k)
		SwGuessTried[lit][k] := 1
		got := lit
		t0 := SwNow()
		while (SwNow() - t0 < wait / 1000.0)
			{
			n := SwGuessStars()
			if (n > lit)
				{
				got := n
				break
				}
			if (n = 0 and lit = 11)
				{
				got := 12
				break
				}
			if (n >= 0 and n < lit - 1)
				{
				got := -1
				break
				}
			}
		if (got < 0)
			{
			log .= "(stars reset)"
			break
			}
		log .= k . ((got > lit) ? "+ " : "x ")
		if (got > lit)
			{
			SwSlotSt[k] := 3
			SwMemMark(k)
			lit := got
			if (lit >= 12)
				SwMemReset()
			}
		}
	VarSetCapacity(pt, 8, 0)
	NumPut(Round(LookDownX), pt, 0, "Int")
	NumPut(Round(LookDownY), pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	CoordMode, Mouse, Screen
	MouseMove, % NumGet(pt, 0, "Int"), % NumGet(pt, 4, "Int"), 0
	CoordMode, Mouse, Client
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	SwFailN := 0
	SwLastStep := SwNow()
	SwLastClick := SwLastStep
	SwGuessMsg := "slots tried: " . log . " (+ = right, x = wrong)"
	SwLog("auto retry " . log)
}

SwClickStepMax() {
	global SwVetoM, SwVetoZ, SwRecZ
	global SwMaxSigns, SwRetryFails
	global SwClickSigns, SwStop, SwStopWhy, SwPhase, SwStarsValid, SwFound, SwFishX, SwLit, SwK0, SwOrder, SwSlotSt, SwSlotFirst, SwClicks, SwClickAt, SwClickLit, SwClickSlot, SwFastClicks
	global SwRetry, SwLastClick, SwLastOnset, SwTie, SwLockFail, SwBarL, SwBarW, SwS, SwSB, SwFrMiss, WindowWidth, SwPhaseT, SwStarStableT, SwPurpleN, SwFrMoveT, SwLitRaw, SwClickTook, SwLitRawT
	global SwAllSigns, SwTieWas, SwSlotGone, PrecisionDown, PrecisionDownAt, QpcFreq, SwSignsFirst, SwFailN, SwFailAt, SwBurstN, SwRetryK, SwGuessOn, SwGuessDone, SwGuessGuess
	if (SwGuessOn and SwPhase and SwClickSigns and !SwLockFail and !SwGuessDone and SwStarsValid and SwLit >= (SwGuessGuess ? 12 - SwGuessN() : 11) and SwLit < 12)
		{
		if (SwGuessGuess and SwGuessReady())
			{
			gl := SwGuessStars()
			if (gl >= 12 - SwGuessN() and gl < 12)
				{
				SwGuessRun(gl)
				return
				}
			}
		else if (SwLit = 11 and SwLastOnly())
			return
		}
	if (SwRetryK and SwPhase and SwClickSigns and !SwStop and !SwLockFail)
		{
		SwRetryFire()
		return
		}
	if (SwPhase and SwClickSigns)
		SwCursorGuard()
	if (!SwClickSigns or SwStop or SwLockFail or !SwPhase or !SwStarsValid or !SwFound or (SwFishX < 0 and !SwSignsFirst))
		return
	now := SwNow()
	if (SwClickAt)
		{
		got := SwLit - SwClickLit
		if (SwLit = 0 and SwClickLit > 0 and SwClickLit + SwBurstN >= 12)
			got := SwBurstN
		if (got > 0)
			{
			bi := SwClickLit - SwK0 + 1
			Loop % ((got < SwBurstN) ? got : SwBurstN)
				{
				bj := bi + A_Index - 1
				if (bj >= 1 and bj <= SwOrder.Length())
					{
					SwSlotSt[SwOrder[bj]] := 3
					SwMemMark(SwOrder[bj])
					}
				}
			if (SwClickLit + got >= 12)
				SwMemReset()
			SwRetry := 0
			SwFailN := 0
			SwPurpleN := 0
			if (got >= SwBurstN)
				{
				SwClickAt := 0
				SwLog("click ok lit " . SwLit . " burst " . SwBurstN)
				return
				}
			SwBurstN := SwBurstN - got
			SwClickLit := SwLit
			SwClickAt := now
			bj := SwLit - SwK0 + 1
			if (bj >= 1 and bj <= SwOrder.Length())
				SwClickSlot := SwOrder[bj]
			return
			}
		if (SwLit != SwClickLit)
			{
			; the count dropped - nearly always a one-frame misread, so wait for it to come back
			if (now - SwLitRawT < 0.4)
				return
			SwStop := true
			SwStopWhy := "lit " . SwClickLit . "->" . SwLit
			SwLog("stop: " . SwStopWhy)
			return
			}
		if (now - SwClickAt < (SwMaxSigns ? TA("swfailmax", 400) : TA("swfail", 1000)) / 1000.0 + SwClickTook)
			return
		if (SwSlotWhite(SwClickSlot))
			{
			if (now - SwClickAt < (SwMaxSigns ? TA("swfailmax", 400) : TA("swfail", 1000)) / 1000.0)
				return
			if (SwSoftFail("white", now))
				return
			SwStop := true
			SwStopWhy := "white, star not lit"
			SwLog("stop: " . SwStopWhy)
			return
			}
		if (SwSlotStrokes(SwClickSlot) >= 2)
			SwPurpleN := SwPurpleN + 1
		else
			SwPurpleN := 0
		if (SwPurpleN >= 2 and SwRetry < (SwRetryFails ? 3 : 1) and !(SwFrMoveT and now - SwFrMoveT < (SwMaxSigns ? 0.05 : 0.4)) and now - SwLitRawT >= (SwMaxSigns ? 0.1 : 0.3))
			{
			SwRetry := SwRetry + 1
			SwPurpleN := 0
			SwLog("retry " . SwRetry . " slot " . SwClickSlot . " (still purple)")
			rk := SwPurpleTarget()
			if (rk)
				SwRetryClick(rk)
			return
			}
		if (now - SwClickAt < (SwMaxSigns ? TA("swgiveupmax", 600) : TA("swgiveup", 1500)) / 1000.0)
			return
		if (SwSoftFail("click failed", now))
			return
		SwStop := true
		SwStopWhy := "click failed"
		SwLog("stop: " . SwStopWhy)
		return
		}
	if (SwFailAt and now < SwFailAt)
		return
	if (SwLit != SwLitRaw)
		return
	if (SwK0 < 0)
		{
		if (now - SwStarStableT < SwSec(SwMaxSigns ? 0 : 0.1) or now - SwLitRawT < SwSec(SwMaxSigns ? 0 : (1 ? 0.1 : 0.3)) or !SwOrder.Length())
			return
		SwK0 := SwLit
		SwLog("k0 " . SwK0)
		}
	if (SwLit >= 12 or now - SwLastClick < SwSec(1 ? 0 : (SwFastClicks ? 0.05 : 0.2)))
		return
	if (SwLit < SwK0)
		{
		if (now - SwLitRawT < 0.4)
			return
		SwStop := true
		SwStopWhy := "lit below k0"
		SwLog("stop: " . SwStopWhy)
		return
		}
	i := SwLit - SwK0 + 1
	if (i > SwOrder.Length())
		return
	k := SwOrder[i]
	if (SwSlotSt[k] = 3)
		{
		; its star went out again (misread, or the click did not hold) and the sign is still there - click it again
		if (SwSlotStrokes(k) >= 2 and !SwSlotWhite(k))
			{
			SwSlotSt[k] := 2
			SwLog("sign back slot " . k)
			}
		else
			{
			SwStop := true
			SwStopWhy := "target already clicked"
			SwLog("stop: " . SwStopWhy . " slot " . k)
			return
			}
		}
	fast := (1 or (SwFastClicks and !SwTie[k] and !SwTieWas[k]))
	if (now - SwSlotFirst[k] < SwSec(1 ? 0 : (fast ? 0.1 : 0.35)) or (!SwFailN and SwSlotWhite(k)))
		return
	if (SwAllSigns and SwOrder.Length() < SwWaitNeed() and now - SwLastOnset < TA("swallwait", 700) / 1000.0)
		return
	settled := 1 or (SwOrder.Length() >= 12 - SwK0) or (SwOrder.Length() > i) or (now - SwLastOnset >= SwSec(fast ? 0.15 : 0.35))
	if (!settled)
		return
	if (fast and !1)
		{
		Loop 12
			{
			if (A_Index != k and SwSlotSt[A_Index] = 1 and !SwSlotGone[A_Index] and now - SwSlotFirst[A_Index] < 0.5 and SwSlotFirst[A_Index] <= SwSlotFirst[k] + 0.15)
				return
			}
		}
	if (SwFrMiss or (SwFrMoveT and now - SwFrMoveT < SwSec(SwMaxSigns ? 0.05 : 0.4)))
		return
	if (!SwSignsFirst and (SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB) and !(!PrecisionDown and SwFishX < SwBarL - 10 * SwSB))
		return
	z := Mod(SwK0 + i - 1, 12)
	if (SwTie[k])
		{
		j := i + 1
		while (j <= SwOrder.Length() and SwTie[SwOrder[j]])
			j++
		if (j - 1 > i)
			{
			best := k
			bestS := -9
			secondS := -9
			nleft := 0
			lone := 0
			firstLeft := 0
			Loop % j - i
				{
				kk := SwOrder[i + A_Index - 1]
				tdZ := -1
				tdS := -9
				sc := SwTplBest2(kk, z, tdZ, tdS)
				if (tdS >= 0.5 and tdZ != z and tdS >= sc + 0.2)
					{
					SwLog("tie drop slot " . kk . " looks like " . SwZodiac(tdZ) . " (" . Round(tdS, 3) . ")")
					continue
					}
				if (nleft = 0)
					firstLeft := kk
				nleft++
				lone := kk
				if (sc > bestS)
					{
					secondS := bestS
					bestS := sc
					best := kk
					}
				else if (sc > secondS)
					secondS := sc
				}
			if (nleft = 1)
				best := lone
			else if (nleft > 1 and !(bestS >= 0.5 and bestS - secondS >= 0.08))
				{
				best := firstLeft
				SwLog("tie by order slot " . best . " for " . SwZodiac(z) . " (" . Round(bestS, 3) . " vs " . Round(secondS, 3) . ")")
				}
			if (nleft = 0)
				{
				if (SwRetryFails)
					{
					SwVetoWait(i, k, z, now)
					return
					}
				if (now - SwLastOnset > 1.0)
					{
					SwStop := true
					SwStopWhy := "tie unresolved " . SwZodiac(z)
					SwLog("stop: " . SwStopWhy . " (" . Round(bestS, 3) . " vs " . Round(secondS, 3) . ")")
					}
				return
				}
			if (best != k)
				{
				Loop % SwOrder.Length()
					{
					if (SwOrder[A_Index] = best)
						{
						SwOrder.RemoveAt(A_Index)
						break
						}
					}
				SwOrder.InsertAt(i, best)
				SwLog("tie pick slot " . best . " for " . SwZodiac(z) . " (" . Round(bestS, 3) . ")")
				k := best
				}
			}
		SwTie[k] := 0
		}
	if (fast)
		{
		if (PrecisionDown and !SwSignsFirst)
			{
			DllCall("QueryPerformanceCounter", "Int64*", qn)
			if ((qn - PrecisionDownAt) * 1000.0 / QpcFreq < SwMs(250))
				return
			}
		if (SwTplOk(k, z) = 0)
			{
			if (SwRetryFails)
				{
				SwVetoWait(i, k, z, now)
				return
				}
			SwStop := true
			SwStopWhy := "shape veto " . SwZodiac(z) . " slot " . k
			SwLog("stop: " . SwStopWhy)
			return
			}
		k := SwPickSign(i, k, z, 0.1)
		if (SwMaxSigns and !SwFailN)
			SwBurstMax(i, k, now)
		else
			SwDoClickMax(k, now, SwFailN > 0)
		return
		}
	res := SwTplOk(k, z)
	if (res = 1)
		{
		k := SwPickSign(i, k, z, 0.1)
		SwDoClickMax(k, now, SwFailN > 0)
		return
		}
	if (res = 3)
		return
	if (SwRetryFails)
		{
		SwVetoWait(i, k, z, now)
		return
		}
	SwStop := true
	SwStopWhy := "shape veto " . SwZodiac(z) . " slot " . k
	SwLog("stop: " . SwStopWhy)
}

SwBurstMax(i, k, now) {
	global SwOrder, SwSlotSt, SwTie, SwK0, SwLit, SwStop, SwBurstN, SwNextI, SwClickLit, SwClickSlot
	global SwSignsFirst, SwFishX, SwBarL, SwBarW, SwSB, SwRetryFails, SwGuessOn, SwGuessGuess
	lit0 := SwLit
	SwNextI := i + 1
	if (!SwDoClickMax(k, now, false))
		{
		SwNextI := 0
		return
		}
	n := 1
	j := i + 1
	cap := SwGuessOn ? 12 - (SwGuessGuess ? SwGuessN() : 1) : 12
	while (j <= SwOrder.Length() and lit0 + n < cap and !SwStop)
		{
		kk := SwOrder[j]
		if (SwSlotSt[kk] != 2 or SwTie[kk] or SwSlotWhite(kk))
			break
		if (!SwSignsFirst and (SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB))
			break
		if (SwTplOk(kk, Mod(SwK0 + j - 1, 12)) = 0)
			break
		SwNextI := j + 1
		if (!SwDoClickMax(kk, SwNow(), false))
			break
		n++
		j++
		}
	SwNextI := 0
	SwBurstN := n
	SwClickLit := lit0
	SwClickSlot := k
	SwLog("burst " . n . " from lit " . lit0)
}

SwDoClickMax(k, now, slow := false) {
	global SwMaxSigns, SwBurstN, SwNextI
	global RobloxHwnd, PrecisionDown, PrecisionUpAt, SwFishX, SwSB, SwFrTop, FishBarTop, LookDownX, LookDownY, SwClickAt, SwClickLit, SwClickSlot, SwClicks, SwLastClick, SwLit, SwLockFail, SwLockN, SwStop, SwStopWhy, SwLastStep, SwClickTook, SwFastClicks
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwPreNudgeAt, SwK0, SwOrder, SwSlotSt, ControlMode, MacroRunning
	global SwLockStrk, SwLockT
	if (!RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return false
	; the cursor was just pulled away - give it a moment before trying again
	if (SwLockStrk and SwNow() - SwLockT < 0.15)
		return false
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
		}
	if (slow)
		PreciseSleep(30)
	cx := Round(SwSlotX(k))
	if (Abs(SwFishX - cx) < 20 * SwSB)
		cx := cx + ((SwFishX >= cx) ? -Round(22 * SwSB) : Round(22 * SwSB))
	cy := Round(FishBarTop) + SwFrTop + Round(44 * SwSB)
	VarSetCapacity(pt, 8, 0)
	NumPut(cx, pt, 0, "Int")
	NumPut(cy, pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	sx := NumGet(pt, 0, "Int")
	sy := NumGet(pt, 4, "Int")
	CoordMode, Mouse, Screen
	pre := false
	if (SwPreK = k and Abs(sx - SwPreX) <= 3 and Abs(sy - SwPreY) <= 3)
		{
		MouseGetPos, mx, my
		if (Abs(mx - SwPreX - SwPreNudge) <= 2 and Abs(my - SwPreY) <= 2)
			{
			pre := true
			sx := SwPreX
			sy := SwPreY
			}
		}
	if (slow)
		pre := false
	SwPreK := 0
	if (slow)
		{
		MouseMove, %sx%, %sy%, 0
		PreciseSleep(10)
		MouseMove, % sx + 1, % sy, 0
		PreciseSleep(20)
		sx := sx + 1
		}
	else if (pre)
		{
		if (!SwPreNudge)
			{
			PreciseSleep(SwMs((SwMaxSigns ? 10 : 40)) - (SwNow() - SwPreAt) * 1000)
			MouseMove, % sx + 1, % sy, 0
			PreciseSleep(SwMs(SwMaxSigns ? 5 : 30))
			}
		else
			PreciseSleep(SwMs((SwMaxSigns ? 5 : 30)) - (SwNow() - SwPreNudgeAt) * 1000)
		}
	else
		{
		MouseMove, %sx%, %sy%, 0
		if (SwFastClicks or 1)
			PreciseSleep(SwMs(SwMaxSigns ? 10 : 40))
		else
			PreciseSleep(SwMs(75))
		MouseMove, % sx + 1, % sy, 0
		if (SwFastClicks or 1)
			PreciseSleep(SwMs(SwMaxSigns ? 5 : 30))
		else
			PreciseSleep(SwMs(75))
		}
	MouseGetPos, mx, my
	if (Abs(mx - sx) > 8 or Abs(my - sy) > 8)
		{
		CoordMode, Mouse, Client
		; something else moved the cursor (your mouse, remote desktop) - skip this try, give up only after 3 in a row
		SwLockStrk := SwLockStrk + 1
		SwLockT := SwNow()
		SwLog("cursor moved away (" . SwLockStrk . "/3)")
		if (SwLockStrk < 3)
			return false
		SwLockN++
		SwLockFail := true
		SwStop := true
		SwStopWhy := "cursor locked"
		SwLog("stop: cursor locked (" . mx . "," . my . " vs " . sx . "," . sy . ")")
		return false
		}
	SwLockStrk := 0
	send {lbutton down}
	if (slow)
		PreciseSleep(80)
	else if (SwFastClicks or 1)
		PreciseSleep(SwMs(SwMaxSigns ? 20 : 50))
	else
		PreciseSleep(SwMs(90))
	send {lbutton up}
	if (SwFastClicks or 1)
		PreciseSleep(SwMs(SwMaxSigns ? 5 : 40))
	else
		PreciseSleep(SwMs(60))
	nk := 0
	if (MacroRunning and (SwFastClicks or 1) and ControlMode != "Manual" and !SwStop and SwK0 >= 0 and SwLit < 11)
		{
		i := SwNextI ? SwNextI : SwLit - SwK0 + 2
		if (i >= 1 and i <= SwOrder.Length())
			{
			nk := SwOrder[i]
			if (nk = k or SwSlotSt[nk] != 2)
				nk := 0
			}
		}
	if (nk)
		{
		ncx := Round(SwSlotX(nk))
		if (Abs(SwFishX - ncx) < 20 * SwSB)
			ncx := ncx + ((SwFishX >= ncx) ? -Round(22 * SwSB) : Round(22 * SwSB))
		NumPut(ncx, pt, 0, "Int")
		NumPut(cy, pt, 4, "Int")
		DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
		SwPreX := NumGet(pt, 0, "Int")
		SwPreY := NumGet(pt, 4, "Int")
		MouseMove, %SwPreX%, %SwPreY%, 0
		SwPreK := nk
		SwPreNudge := 0
		SwPreAt := SwNow()
		}
	else
		{
		NumPut(Round(LookDownX), pt, 0, "Int")
		NumPut(Round(LookDownY), pt, 4, "Int")
		DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
		px := NumGet(pt, 0, "Int")
		py := NumGet(pt, 4, "Int")
		MouseMove, %px%, %py%, 0
		}
	CoordMode, Mouse, Client
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	SwClickAt := SwNow()
	SwClickTook := SwClickAt - now
	SwClickLit := SwLit
	SwClickSlot := k
	SwBurstN := 1
	SwClicks++
	SwLastClick := SwClickAt
	SwLastStep := SwClickAt
	SwLog("click slot " . k . " at " . cx . "," . cy . " lit " . SwLit . " took " . Round((SwClickAt - now) * 1000) . (pre ? " pre" : "") . (SwPreK ? " next " . SwPreK : ""))
	return true
}

SwClickStep() {
	global SwFrStillT, SwVetoM, SwVetoZ, SwDwell, SwDwellPN, SwPressN, SwClickStall, SwFrameT, SwReactEst, SwUnsureK, SwUnsureT, SwUnsureR, SwPressK, SwWantK, SwWantT, SwLitRaw
	global SwClickSigns, SwStop, SwStopWhy, SwPhase, SwStarsValid, SwFound, SwFishX, SwLit, SwK0, SwOrder, SwSlotSt, SwSlotFirst, SwClicks, SwClickAt, SwClickLit, SwClickSlot, SwFastClicks
	global SwRetry, SwLastClick, SwLastOnset, SwTie, SwLockFail, SwBarL, SwBarW, SwS, SwSB, SwFrMiss, WindowWidth, SwPhaseT, SwStarStableT, SwPurpleN, SwFrMoveT, SwLitRaw, SwClickTook, SwLitRawT
	global SwTieWas, SwSlotGone, PrecisionDown, PrecisionDownAt, QpcFreq, SwSlotBlind, SwBarHold, MacroRunning, SwRetryClicks, SwTryAt, SwOverS
	global SwMaxSigns, SwRetryFails, SwFailN, SwFailAt, SwRetryK, SwGuessOn, SwGuessDone, SwGuessGuess, SwAllSigns, SwAllN, SwAllT, SwAllI, FishBarLeft, SwSignsFirst
	SwRetryClicks := SwRetryFails
	SwPressTick()
	if (SwMaxSigns and !SwPressK and !SwWantK)
		{
		SwClickStepMax()
		return
		}
	if (SwPhase and SwClickSigns)
		SwCursorGuard()
	if (SwPressK)
		return
	if (SwAllN)
		{
		nowA := SwNow()
		got := SwLit - SwClickLit
		if (SwLit = 0 and SwClickLit > 0 and SwClickLit + SwAllN >= 12)
			got := SwAllN
		if (got > SwAllN)
			got := SwAllN
		if (got < SwAllN and nowA - SwClickAt < TA("swallconf", 450) / 1000.0)
			return
		if (got < 0)
			got := 0
		Loop % got
			{
			bj := SwAllI + A_Index - 1
			if (bj >= 1 and bj <= SwOrder.Length())
				{
				SwSlotSt[SwOrder[bj]] := 3
				SwMemMark(SwOrder[bj])
				SwGlowAdd(Round(SwSlotX(SwOrder[bj])) - Round(FishBarLeft), nowA)
				}
			}
		SwLog("all-signs burst " . got . "/" . SwAllN . " confirmed")
		if (SwClickLit + got >= 12)
			SwMemReset()
		n0 := SwAllN
		SwAllN := 0
		if (got > 0)
			{
			SwClickAt := 0
			SwRetry := 0
			SwFailN := 0
			SwPurpleN := 0
			SwPressN := 0
			SwTryAt := 0
			SwOverS := 0
			SwDwell := false
			return
			}
		bj := SwAllI
		if (bj >= 1 and bj <= SwOrder.Length())
			SwClickSlot := SwOrder[bj]
		}
	if (SwGuessOn and SwPhase and SwClickSigns and !SwLockFail and !SwGuessDone and SwStarsValid and SwLit >= (SwGuessGuess ? 12 - SwGuessN() : 11) and SwLit < 12)
		{
		if (SwGuessGuess and SwGuessReady())
			{
			gl := SwGuessStars()
			if (gl >= 12 - SwGuessN() and gl < 12)
				{
				SwGuessRun(gl)
				return
				}
			}
		else if (SwLit = 11 and SwLastOnly())
			return
		}
	if (SwRetryK and SwPhase and SwClickSigns and !SwStop and !SwLockFail)
		{
		SwRetryFire()
		return
		}
	if (SwWantK)
		{
		if (SwStop or SwLockFail or !SwPhase or !SwClickSigns or !MacroRunning)
			SwWantK := 0
		else if (SwSlotWhite(SwWantK) or (SwClickAt and SwWantK = SwClickSlot and (SwLitRaw = SwClickLit + 1 or (SwClickLit = 11 and SwLitRaw = 0))))
			{
			SwLog("want dropped slot " . SwWantK)
			SwWantK := 0
			}
		else if (SwNow() - SwWantT > 0.25)
			{
			SwLog("want expired slot " . SwWantK)
			SwWantK := 0
			}
		else if ((!SwFound and !SwBarHold) or (SwFishX < 0 and !SwSignsFirst))
			return
		else if (!SwSignsFirst and (SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB) and !(SwFastClicks and !PrecisionDown and SwFishX < SwBarL - 10 * SwSB))
			{
			SwLog("want dropped slot " . SwWantK . " (fish outside)")
			SwWantK := 0
			}
		else
			{
			SwDoClick(SwWantK, SwWantT)
			return
			}
		}
	if (!SwClickSigns or SwStop or SwLockFail or !SwPhase or !SwStarsValid)
		return
	now := SwNow()
	if (SwClickAt and (SwLit = SwClickLit + 1 or (SwClickLit = 11 and SwLit = 0)))
		{
		if (SwDwell)
			SwReactLearn()
		SwSlotSt[SwClickSlot] := 3
		SwMemMark(SwClickSlot)
		if (SwClickLit = 11)
			SwMemReset()
		SwClickAt := 0
		SwFailN := 0
		SwRetry := 0
		SwPurpleN := 0
		SwPressN := 0
		SwTryAt := 0
		SwOverS := 0
		SwLog("click ok slot " . SwClickSlot . " lit " . SwLit)
		if (SwDwell)
			SwDwellEnd()
		return
		}
	if ((!SwFound and !SwBarHold) or (SwFishX < 0 and !SwSignsFirst))
		return
	if (SwClickAt)
		{
		if (SwLit != SwClickLit)
			{
			; Retry failed clicks: an earlier click went through late, so two stars lit - count them both and go on
			if (SwRetryClicks and SwLit > SwClickLit + 1 and SwK0 >= 0)
				{
				bi := SwClickLit - SwK0 + 1
				Loop % SwLit - SwClickLit
					{
					bj := bi + A_Index - 1
					if (bj >= 1 and bj <= SwOrder.Length())
						{
						SwSlotSt[SwOrder[bj]] := 3
						SwMemMark(SwOrder[bj])
						}
					}
				SwSlotSt[SwClickSlot] := 3
				SwMemMark(SwClickSlot)
				if (SwLit >= 12)
					SwMemReset()
				SwLog("resync lit " . SwClickLit . "->" . SwLit)
				SwClickAt := 0
				SwFailN := 0
				SwRetry := 0
				SwPurpleN := 0
				SwPressN := 0
				SwTryAt := 0
				SwOverS := 0
				if (SwDwell)
					SwDwellEnd()
				return
				}
			if (SwLit < SwClickLit and now - SwLitRawT < 0.4)
				return
			SwStop := true
			SwStopWhy := "lit " . SwClickLit . "->" . SwLit
			SwLog("stop: " . SwStopWhy)
			return
			}
		ta := (SwRetryClicks and SwTryAt > SwClickAt) ? SwTryAt : SwClickAt
		fout := !SwSignsFirst and (SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB) and !(SwFastClicks and !PrecisionDown and SwFishX < SwBarL - 10 * SwSB)
		left := SwRetryClicks and SwPressN + SwRetry < 3 and SwClickSlot != SwOverS
		more := left and !fout
		if (SwDwell)
			{
			if (SwLitRaw != SwClickLit or SwSlotWhite(SwClickSlot) or SwFrameT - SwClickAt >= 0.5)
				{
				if (SwLitRaw = SwClickLit + 1 or (SwClickLit = 11 and SwLitRaw = 0))
					SwReactLearn()
				SwDwellEnd()
				}
			else
				{
				SwDwellPN := (SwSlotStrokes(SwClickSlot) >= 2) ? SwDwellPN + 1 : 0
				fl := Max(0.35, 1.5 * SwReactEst) + SwClickStall
				if (SwDwellPN >= 2 and (SwRetryClicks ? more : SwPressN < 1) and fl <= 0.45 and SwFrameT - ta >= fl and !(SwFrMoveT and now - SwFrMoveT < 0.4))
					{
					SwPressN := SwPressN + 1
					SwDwellPN := 0
					SwTryAt := now
					; it did not take - it may be the wrong sign, so press the one that reads most like the due zodiac
					rk := SwPurpleTarget()
					SwLog("repress " . SwPressN . " slot " . rk)
					if (rk and rk != SwClickSlot)
						SwDwellEnd()
					if (rk)
						SwDoClick(rk, now)
					return
					}
				}
			}
		swW := SwRetryClicks ? Min(0.7, Max(0.4, 2.0 * SwReactEst)) : 1.0
		if (now - ta < swW + SwClickTook)
			return
		if (SwSlotWhite(SwClickSlot))
			{
			if (now - SwClickAt < (SwRetryClicks ? swW + 0.2 : 1.0) or (SwLitRaw != SwClickLit and now - SwClickAt < (SwRetryClicks ? 1.1 : 1.5)))
				return
			if (SwSoftFail("white", now))
				return
			SwStop := true
			SwStopWhy := "white, star not lit"
			SwLog("stop: " . SwStopWhy)
			return
			}
		if (SwSlotStrokes(SwClickSlot) >= 2)
			SwPurpleN := SwPurpleN + 1
		else
			SwPurpleN := 0
		if (SwPurpleN >= 2 and (SwRetryClicks ? more : SwRetry < 1) and !(SwFrMoveT and now - SwFrMoveT < 0.4) and now - SwLitRawT >= 0.3)
			{
			SwRetry := SwRetry + 1
			SwPurpleN := 0
			SwTryAt := now
			SwLog("retry " . SwRetry . " slot " . SwClickSlot . " (still purple)")
			rk := SwPurpleTarget()
			if (rk)
				SwRetryClick(rk)
			return
			}
		if (now - ta < (SwRetryClicks ? swW + 0.5 : 1.5) or (left and fout))
			return
		if (SwSoftFail("click failed", now))
			return
		SwStop := true
		SwStopWhy := "click failed"
		SwLog("stop: " . SwStopWhy)
		return
		}
	if (SwFailAt and now < SwFailAt)
		return
	if (SwLit != SwLitRaw)
		return
	if (SwK0 < 0)
		{
		if (now - SwStarStableT < 0.1 or now - SwLitRawT < 0.3 or !SwOrder.Length())
			return
		SwK0 := SwLit
		SwLog("k0 " . SwK0)
		}
	if (SwLit >= 12 or now - SwLastClick < (SwFastClicks ? 0.05 : 0.2))
		return
	if (SwLit < SwK0)
		{
		if (now - SwLitRawT < 0.4)
			return
		SwStop := true
		SwStopWhy := "lit below k0"
		SwLog("stop: " . SwStopWhy)
		return
		}
	i := SwLit - SwK0 + 1
	if (i > SwOrder.Length())
		return
	k := SwOrder[i]
	if (SwSlotSt[k] = 3)
		{
		; its star went out again (misread, or the click did not hold) and the sign is still there - click it again
		if (SwSlotStrokes(k) >= 2 and !SwSlotWhite(k))
			{
			SwSlotSt[k] := 2
			SwLog("sign back slot " . k)
			}
		else
			{
			SwStop := true
			SwStopWhy := "target already clicked"
			SwLog("stop: " . SwStopWhy . " slot " . k)
			return
			}
		}
	if (!SwFound and (SwTie[k] or SwTieWas[k]))
		return
	fast := (SwFastClicks and !SwTie[k] and !SwTieWas[k])
	if (now - SwSlotFirst[k] < (SwFastClicks ? (SwTie[k] ? 0.2 : 0.1) : 0.35) or SwSlotWhite(k))
		return
	if (SwAllSigns and SwOrder.Length() < SwWaitNeed() and now - SwLastOnset < TA("swallwait", 700) / 1000.0)
		return
	settled := (SwOrder.Length() >= 12 - SwK0) or (SwOrder.Length() > i) or (now - SwLastOnset >= (SwFastClicks ? 0.15 : 0.35))
	if (!settled)
		return
	if (fast)
		{
		Loop 12
			{
			if (A_Index != k and SwSlotSt[A_Index] = 1 and !SwSlotGone[A_Index] and now - SwSlotFirst[A_Index] < 0.5 and (SwSlotFirst[A_Index] <= SwSlotFirst[k] + 0.15 or Max(SwSlotBlind[A_Index], SwPhaseT) <= SwSlotFirst[k] + 0.15))
				return
			}
		}
	if (SwFrMiss or (SwFrMoveT and now - SwFrMoveT < 0.4 and now - SwFrStillT < 0.15))
		return
	if (!SwAllSigns and !SwSignsFirst and (SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB) and !(SwFastClicks and !PrecisionDown and SwFishX < SwBarL - 10 * SwSB))
		return
	z := Mod(SwK0 + i - 1, 12)
	if (SwTie[k])
		{
		j := i + 1
		while (j <= SwOrder.Length() and SwTie[SwOrder[j]])
			j++
		if (j - 1 > i)
			{
			best := k
			bestS := -9
			secondS := -9
			nleft := 0
			lone := 0
			firstLeft := 0
			Loop % j - i
				{
				kk := SwOrder[i + A_Index - 1]
				if (z = SwVetoZ and (SwVetoM >> (kk - 1)) & 1)
					continue
				tdZ := -1
				tdS := -9
				sc := SwTplBest2(kk, z, tdZ, tdS)
				if (tdS >= 0.5 and tdZ != z and tdS >= sc + 0.2)
					{
					SwLog("tie drop slot " . kk . " looks like " . SwZodiac(tdZ) . " (" . Round(tdS, 3) . ")")
					continue
					}
				if (nleft = 0)
					firstLeft := kk
				nleft++
				lone := kk
				if (sc > bestS)
					{
					secondS := bestS
					bestS := sc
					best := kk
					}
				else if (sc > secondS)
					secondS := sc
				}
			if (nleft = 1)
				best := lone
			else if (nleft > 1 and !(bestS >= 0.5 and bestS - secondS >= 0.08))
				{
				best := firstLeft
				SwLog("tie by order slot " . best . " for " . SwZodiac(z) . " (" . Round(bestS, 3) . " vs " . Round(secondS, 3) . ")")
				}
			if (nleft = 0)
				{
				if (SwRetryFails)
					{
					SwVetoWait(i, k, z, now)
					return
					}
				if (SwRecover(i, z))
					return
				if (now - SwLastOnset > 1.0)
					{
					SwStop := true
					SwStopWhy := "tie unresolved " . SwZodiac(z)
					SwLog("stop: " . SwStopWhy . " (" . Round(bestS, 3) . " vs " . Round(secondS, 3) . ")")
					}
				return
				}
			if (best != k)
				{
				Loop % SwOrder.Length()
					{
					if (SwOrder[A_Index] = best)
						{
						SwOrder.RemoveAt(A_Index)
						break
						}
					}
				SwOrder.InsertAt(i, best)
				SwLog("tie pick slot " . best . " for " . SwZodiac(z) . " (" . Round(bestS, 3) . ")")
				k := best
				}
			}
		SwTie[k] := 0
		}
	if (SwFastClicks and PrecisionDown and !SwSignsFirst)
		{
		DllCall("QueryPerformanceCounter", "Int64*", qn)
		if ((qn - PrecisionDownAt) * 1000.0 / QpcFreq < 250)
			return
		}
	if (fast)
		{
		if (SwTplOk(k, z) = 0)
			{
			if (SwRecover(i, z))
				return
			if (SwRetryClicks)
				{
				SwVetoWait(i, k, z, now)
				return
				}
			SwStop := true
			SwStopWhy := "shape veto " . SwZodiac(z) . " slot " . k
			SwLog("stop: " . SwStopWhy)
			return
			}
		k := SwPickSign(i, k, z, 0.1)
		SwDoClick(k, now)
		return
		}
	res := SwTplOk(k, z)
	if (res = 1)
		{
		k := SwPickSign(i, k, z, 0.1)
		SwDoClick(k, now)
		return
		}
	rearm := (SwTieWas[k] and i < SwOrder.Length() and SwTie[SwOrder[i + 1]])
	if (res = 3)
		{
		if (SwUnsureK != k * 16 + z)
			{
			SwUnsureK := k * 16 + z
			SwUnsureT := now
			}
		if ((!SwFastClicks and !SwRetryClicks) or now - SwUnsureT < 0.2)
			return
		if (rearm and SwUnsureR != k * 16 + z)
			{
			SwUnsureR := k * 16 + z
			SwTie[k] := 1
			SwLog("unsure retie slot " . k . " for " . SwZodiac(z))
			return
			}
		if (SwRetryClicks and SwFindSign(i, z, k, true))
			return
		SwLog("unsure click slot " . k . " for " . SwZodiac(z))
		SwDoClick(k, now)
		return
		}
	if (SwRecover(i, z))
		return
	if (rearm)
		{
		if (SwVetoZ != z)
			{
			SwVetoZ := z
			SwVetoM := 0
			}
		SwVetoM := SwVetoM | (1 << (k - 1))
		SwTie[k] := 1
		SwLog("tie retry slot " . k . " not " . SwZodiac(z))
		return
		}
	if (SwRetryClicks)
		{
		SwVetoWait(i, k, z, now)
		return
		}
	SwStop := true
	SwStopWhy := "shape veto " . SwZodiac(z) . " slot " . k
	SwLog("stop: " . SwStopWhy)
}

SwMs(ms) {
	global TimeOffset
	off := TimeOffset
	if off is not number
		off := 0
	v := ms + off
	return (v < 0) ? 0 : v
}

SwSec(sec) {
	global TimeOffset
	off := TimeOffset
	if off is not number
		off := 0
	v := sec + off / 1000.0
	return (v < 0) ? 0 : v
}

SwClickFirst() {
	global SpecialRod, SwSignsFirst, SwClickSigns, SwPhase, SwStop, SwLockFail, SwLit, SwK0, SwOrder, SwClickAt, SwRetryK, SwAllN
	if (SpecialRod != "Stellarwave Melody" or !SwSignsFirst or !SwClickSigns or !SwPhase or SwStop or SwLockFail or SwLit >= 12)
		return false
	if (SwClickAt or SwRetryK or SwAllN)
		return true
	if (SwK0 < 0)
		return (SwOrder.Length() > 0)
	return (SwLit - SwK0 + 1 <= SwOrder.Length())
}

SwOverride(i, k, z, now) {
	global SwOverK, SwOverT, SwOverL, SwOverR, SwOverS, SwRecZ
	if (SwOverK != k * 16 + z or now - SwOverL > 0.1)
		{
		SwOverK := k * 16 + z
		SwOverT := now
		}
	SwOverL := now
	if (now - SwOverT < 0.2)
		return
	if (SwOverR != z)
		{
		SwOverR := z
		SwRecZ := -1
		if (SwRecover(i, z))
			return
		}
	SwOverS := k
	SwLog("veto override slot " . k . " for " . SwZodiac(z))
	SwDoClick(k, now)
}

SwCursorGuard() {
	global RobloxHwnd, MacroRunning, FishBarLeft, FishBarRight, FishBarTop, FishBarBottom, WindowHeight, LookDownX, LookDownY
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwPreNudgeAt, SwStop, SwDwell, SwClickSlot, SwClickAt, SwFastClicks
	global SwPressK, SwHov1, SwMoveOn, SwHyb, SwWantK, SwLockN, SwLockFail, SwStopWhy, SwWantStrk
	if (!MacroRunning or !RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return false
	if (SwPressK)
		return false
	moved := false
	if (SwPreK)
		{
		CoordMode, Mouse, Screen
		MouseGetPos, mx, my
		el := SwNow() - SwPreAt
		if (Abs(mx - SwPreX - SwPreNudge) > 2 or Abs(my - SwPreY) > 2)
			{
			CoordMode, Mouse, Client
			SwPreK := 0
			SwDwell := false
			moved := true
			SwLog("prehover ended (cursor moved)")
			if (SwWantK and (Abs(mx - SwPreX - SwPreNudge) > 8 or Abs(my - SwPreY) > 8))
				{
				SwWantStrk := SwWantStrk + 1
				if (SwWantStrk >= 3)
					{
					SwWantK := 0
					SwLockN++
					SwLockFail := true
					SwStop := true
					SwStopWhy := "cursor locked"
					SwLog("stop: cursor locked (" . mx . "," . my . " vs " . SwPreX . "," . SwPreY . ")")
					}
				}
			}
		else if (SwStop or el >= 0.8)
			{
			CoordMode, Mouse, Client
			SwPreEnd(SwStop ? "stop" : "timeout")
			return true
			}
		else if (SwDwell and SwFastClicks and SwPreK = SwClickSlot and SwNow() - SwClickAt >= SwMoveOn - SwHyb)
			{
			rem := SwMoveOn - (SwNow() - SwClickAt)
			if (rem > 0)
				PreciseSleep(rem * 1000)
			CoordMode, Mouse, Client
			SwPreNext()
			return false
			}
		else
			{
			h1 := SwFastClicks ? SwHov1 : 0.075
			if (!SwPreNudge and el >= h1 - SwHyb)
				{
				rem := h1 - el
				if (rem > 0)
					PreciseSleep(rem * 1000)
				MouseMove, % SwPreX + 1, % SwPreY, 0
				SwPreNudge := 1
				SwPreNudgeAt := SwNow()
				}
			CoordMode, Mouse, Client
			return false
			}
		}
	MouseGetPos, mx, my
	if (my < FishBarTop - 0.03 * WindowHeight or my > FishBarBottom or mx < FishBarLeft or mx > FishBarRight)
		return false
	MouseMove, %LookDownX%, %LookDownY%, 0
	if (moved)
		SwParkSet()
	SwLog("cursor parked from " . mx . "," . my)
	return true
}

SwDoClick(k, now) {
	global RobloxHwnd, PrecisionDown, PrecisionUpAt, SwFishX, SwSB, SwFrTop, FishBarTop, SwClickLit, SwClickSlot, SwLit, SwLockFail, SwLockN, SwStop, SwStopWhy, SwLastStep, SwFastClicks
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwPreNudgeAt, ControlMode, MacroRunning
	global SwDwell, SwPressN, SwWantK, SwWantT, SwWantNom, SwWantPre, SwWantSx, SwWantSy, SwWantCx, SwWantCy, SwPressK, SwPressQ, SwPressMs, SwPressDecT, SwPressNom, SwPressCx, SwPressCy, SwPressPre, SwPressSx, SwPressSy, SwHov1, SwHov2, SwHyb
	global SwWantStrk, SwPressLit, SwMaxSigns, SwLockStrk, SwLockT
	if (SwPressK)
		return false
	if (!RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return false
	if (SwLockStrk and SwNow() - SwLockT < 0.15)
		return false
	wasWant := SwWantK
	atomic := (ControlMode = "Manual" or !MacroRunning)
	nomA := 0
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
		}
	if (wasWant = k)
		{
		cx := SwWantCx
		cy := SwWantCy
		sx := SwWantSx
		sy := SwWantSy
		}
	else
		{
		cx := Round(SwSlotX(k))
		if (Abs(SwFishX - cx) < 20 * SwSB)
			cx := cx + ((SwFishX >= cx) ? -Round(22 * SwSB) : Round(22 * SwSB))
		cy := Round(FishBarTop) + SwFrTop + Round(44 * SwSB)
		VarSetCapacity(pt, 8, 0)
		NumPut(cx, pt, 0, "Int")
		NumPut(cy, pt, 4, "Int")
		DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
		sx := NumGet(pt, 0, "Int")
		sy := NumGet(pt, 4, "Int")
		}
	h1 := SwFastClicks ? SwHov1 : 0.075
	h2 := SwFastClicks ? SwHov2 : 0.075
	CoordMode, Mouse, Screen
	pre := false
	if (SwPreK = k and Abs(sx - SwPreX) <= 3 and Abs(sy - SwPreY) <= 3)
		{
		MouseGetPos, mx, my
		if (Abs(mx - SwPreX - SwPreNudge) <= 2 and Abs(my - SwPreY) <= 2)
			{
			pre := true
			sx := SwPreX
			sy := SwPreY
			}
		}
	if (!pre)
		{
		MouseMove, %sx%, %sy%, 0
		SwPreX := sx
		SwPreY := sy
		SwPreK := k
		SwPreNudge := 0
		SwPreNudgeAt := 0
		SwPreAt := SwNow()
		SwDwell := false
		if (!atomic)
			{
			CoordMode, Mouse, Client
			if (wasWant != k)
				{
				SwWantK := k
				SwWantT := now
				SwWantNom := (h1 + h2) * 1000
				SwWantPre := false
				SwWantSx := sx
				SwWantSy := sy
				SwWantCx := cx
				SwWantCy := cy
				SwWantStrk := 0
				}
			else
				{
				SwWantNom := SwWantNom + (h1 + h2) * 1000
				SwWantPre := false
				}
			return false
			}
		PreciseSleep(h1 * 1000)
		MouseMove, % sx + 1, % sy, 0
		SwPreNudge := 1
		SwPreNudgeAt := SwNow()
		PreciseSleep(h2 * 1000)
		nomA := (h1 + h2) * 1000
		}
	else
		{
		if (!SwPreNudge)
			{
			rem := SwPreAt + h1 - SwNow()
			if (rem > SwHyb and !atomic)
				{
				CoordMode, Mouse, Client
				if (!SwWantK)
					{
					SwWantK := k
					SwWantT := now
					SwWantNom := (rem + h2) * 1000
					SwWantPre := true
					SwWantSx := sx
					SwWantSy := sy
					SwWantCx := cx
					SwWantCy := cy
					SwWantStrk := 0
					}
				return false
				}
			if (rem > 0)
				{
				PreciseSleep(rem * 1000)
				nomA := nomA + rem * 1000
				}
			MouseMove, % sx + 1, % sy, 0
			SwPreNudge := 1
			SwPreNudgeAt := SwNow()
			}
		rem := SwPreNudgeAt + h2 - SwNow()
		if (rem > SwHyb and !atomic)
			{
			CoordMode, Mouse, Client
			if (!SwWantK)
				{
				SwWantK := k
				SwWantT := now
				SwWantNom := rem * 1000
				SwWantPre := true
				SwWantSx := sx
				SwWantSy := sy
				SwWantCx := cx
				SwWantCy := cy
				SwWantStrk := 0
				}
			return false
			}
		if (rem > 0)
			{
			PreciseSleep(rem * 1000)
			nomA := nomA + rem * 1000
			}
		}
	MouseGetPos, mx, my
	CoordMode, Mouse, Client
	if (Abs(mx - sx) > 8 or Abs(my - sy) > 8)
		{
		SwWantK := 0
		SwLockStrk := SwLockStrk + 1
		SwLockT := SwNow()
		SwLog("cursor moved away (" . SwLockStrk . "/3)")
		if (SwLockStrk < 3)
			return false
		SwLockN++
		SwLockFail := true
		SwStop := true
		SwStopWhy := "cursor locked"
		SwLog("stop: cursor locked (" . mx . "," . my . " vs " . sx . "," . sy . ")")
		return false
		}
	SwLockStrk := 0
	pr := SwPressN ? 120 : 90
	SwPressNom := (wasWant ? SwWantNom : nomA) + pr
	SwPressDecT := wasWant ? SwWantT : now
	SwPressPre := wasWant ? SwWantPre : pre
	SwWantK := 0
	SwPreK := 0
	SwDwell := false
	SwPressLit := SwLit
	SwPressCx := cx
	SwPressCy := cy
	SwPressSx := sx
	SwPressSy := sy
	SwPressMs := pr
	SendInput {lbutton down}
	DllCall("QueryPerformanceCounter", "Int64*", SwPressQ)
	SwPressK := k
	SwLastStep := SwNow()
	if (atomic)
		{
		PreciseSleep(pr)
		SwPressEnd()
		}
	return true
}

SwPressTick() {
	global SwPressK, SwPressQ, SwPressMs, QpcFreq, SwHyb
	if (!SwPressK)
		return
	if (GetKeyState("LButton"))
		{
		DllCall("QueryPerformanceCounter", "Int64*", q)
		rem := SwPressMs - (q - SwPressQ) * 1000.0 / QpcFreq
		if (rem > 20)
			return
		if (rem > 0)
			PreciseSleep(rem)
		SendInput {lbutton up}
		}
	SwPressDone()
}

SwPressEnd() {
	global SwPressK
	if (!SwPressK)
		return
	if (GetKeyState("LButton"))
		SendInput {lbutton up}
	SwPressDone()
}

SwPressDone() {
	global SwPressK, SwPressDecT, SwPressNom, SwPressCx, SwPressCy, SwPressPre, SwPressSx, SwPressSy, SwPressN, SwRetry, SwClicks, SwClickAt, SwClickLit, SwClickTook, SwClickStall, SwPress0At, SwLastClick, SwLastStep
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwPreNudgeAt, SwDwell, SwDwellPN, PrecisionUpAt, MacroRunning, ControlMode, SwPressLit, SwClickSlot
	k := SwPressK
	SwPressK := 0
	SwClickLit := SwPressLit
	SwClickSlot := k
	SwPreX := SwPressSx
	SwPreY := SwPressSy
	SwPreNudge := 1
	SwPreNudgeAt := SwNow()
	SwPreAt := SwPreNudgeAt
	SwPreK := k
	SwDwell := true
	SwDwellPN := 0
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	SwClickAt := SwNow()
	if (!SwPressN)
		SwPress0At := SwClickAt
	SwClickTook := SwClickAt - SwPressDecT
	SwClickStall := SwClickTook - SwPressNom / 1000.0
	if (SwClickStall < 0)
		SwClickStall := 0
	if (!SwRetry and !SwPressN)
		SwClicks++
	SwLastClick := SwClickAt
	SwLastStep := SwClickAt
	SwLog("click slot " . k . " at " . SwPressCx . "," . SwPressCy . " lit " . SwClickLit . " took " . Round(SwClickTook * 1000) . (SwPressPre ? " pre" : "") . (SwPressN ? " repress" : ""))
	if (!MacroRunning or ControlMode = "Manual")
		SwPreEnd("park")
}

SwDwellEnd() {
	global SwDwell, SwPreK, SwClickSlot
	SwDwell := false
	if (!SwPreK or SwPreK != SwClickSlot)
		return
	if (!SwPreNext())
		SwPreEnd("done")
}

SwPreNext() {
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwFastClicks, MacroRunning, ControlMode, SwStop, SwK0, SwClickLit, SwOrder, SwSlotSt, SwClickSlot
	global SwFishX, SwSB, SwFrTop, FishBarTop, RobloxHwnd
	nk := 0
	if (MacroRunning and SwFastClicks and ControlMode != "Manual" and !SwStop and SwK0 >= 0 and SwClickLit < 11 and RobloxHwnd and WinActive("ahk_id " . RobloxHwnd))
		{
		i := SwClickLit - SwK0 + 2
		if (i >= 1 and i <= SwOrder.Length())
			{
			nk := SwOrder[i]
			if (nk = SwClickSlot or SwSlotSt[nk] != 2)
				nk := 0
			}
		}
	if (!nk)
		return false
	cx := Round(SwSlotX(nk))
	if (Abs(SwFishX - cx) < 20 * SwSB)
		cx := cx + ((SwFishX >= cx) ? -Round(22 * SwSB) : Round(22 * SwSB))
	cy := Round(FishBarTop) + SwFrTop + Round(44 * SwSB)
	VarSetCapacity(pt, 8, 0)
	NumPut(cx, pt, 0, "Int")
	NumPut(cy, pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	SwPreX := NumGet(pt, 0, "Int")
	SwPreY := NumGet(pt, 4, "Int")
	CoordMode, Mouse, Screen
	MouseMove, %SwPreX%, %SwPreY%, 0
	CoordMode, Mouse, Client
	SwPreK := nk
	SwPreNudge := 0
	SwPreAt := SwNow()
	SwLog("prehover slot " . nk)
	return true
}

SwReactLearn() {
	global SwFrameT, SwClickAt, SwPress0At, SwPressN, SwReactEst
	lat := SwFrameT - SwClickAt
	if (SwPressN and lat < 0.10)
		lat := SwFrameT - SwPress0At
	SwReactEst := Max(lat, 0.8 * SwReactEst)
}

SwPreEnd(why) {
	global SwPreK, RobloxHwnd, SwParkX, SwParkY, SwDwell, SwPressK, SwParkAt
	if (SwPressK)
		SwPressEnd()
	if (!SwPreK)
		return
	SwPreK := 0
	SwDwell := false
	; the fight is over in passive mode: leave the mouse where it is
	if (PasIdle())
		SwParkAt := 0
	else if (RobloxHwnd)
		{
		SwParkSet()
		CoordMode, Mouse, Screen
		MouseMove, %SwParkX%, %SwParkY%, 0
		CoordMode, Mouse, Client
		}
	SwLog("prehover ended (" . why . ")")
}

SwParkSet() {
	global RobloxHwnd, LookDownX, LookDownY, SwParkAt, SwParkX, SwParkY, SwParkNudge
	VarSetCapacity(pt, 8, 0)
	NumPut(Round(LookDownX), pt, 0, "Int")
	NumPut(Round(LookDownY), pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	SwParkX := NumGet(pt, 0, "Int")
	SwParkY := NumGet(pt, 4, "Int")
	SwParkAt := SwNow()
	SwParkNudge := 0
}

SwParkWait() {
	global SwParkAt, SwParkX, SwParkY, SwParkNudge
	el := SwNow() - SwParkAt
	if (el >= 0.07)
		{
		SwParkAt := 0
		return false
		}
	if (!SwParkNudge and el >= 0.04)
		{
		CoordMode, Mouse, Screen
		MouseMove, % SwParkX + 1, % SwParkY, 0
		CoordMode, Mouse, Client
		SwParkNudge := 1
		}
	return true
}

SwTplOk(k, z) {
	global SwTie, SwLastOnset, SwSlotFirst
	SwTplMask(k, m, kn)
	if (!IsObject(m))
		return 3
	s0 := SwTplScore(m, kn, z)
	s1 := SwTplScore(m, kn, Mod(z + 11, 12))
	s2 := SwTplScore(m, kn, Mod(z + 1, 12))
	SwLog("shape slot " . k . " " . SwZodiac(z) . " " . Round(s0, 3) . " prev " . Round(s1, 3) . " next " . Round(s2, 3))
	if (z < 11 and s2 >= 0.5 and s2 >= s0 + 0.15)
		return 0
	if (s0 < 0.05)
		return 3
	return 1
}

SwRecover(i, z) {
	global SwSlotSt, SwOrder, SwRecZ
	if (!SwTplSumFn() or z = SwRecZ)
		return false
	SwRecZ := z
	n := 0
	fk := 0
	fs := 0
	fo := 0
	Loop 12
		{
		kk := A_Index
		if (SwSlotSt[kk] >= 2 or SwSlotWhite(kk))
			continue
		SwTplMask(kk, m, kn)
		if (!IsObject(m))
			continue
		sc := SwTplScore(m, kn, z)
		ot := -9
		zz := z + 1
		while (zz < 12)
			{
			s := SwTplScore(m, kn, zz)
			if (s > ot)
				ot := s
			zz++
			}
		if (sc >= 0.35 and sc >= ot + 0.10)
			{
			n++
			fk := kk
			fs := sc
			fo := ot
			}
		}
	if (n != 1)
		return false
	SwSlotSt[fk] := 2
	SwOrder.InsertAt(i, fk)
	SwLog("recover slot " . fk . " for " . SwZodiac(z) . " (" . Round(fs, 3) . " vs " . Round(fo, 3) . ")")
	return true
}

SwTplBest2(k, z, ByRef tdZ, ByRef tdS) {
	tdZ := -1
	tdS := -9
	SwTplMask(k, m, kn)
	if (!IsObject(m))
		return -9
	sc := -9
	Loop % 12 - z
		{
		zz := z + A_Index - 1
		s := SwTplScore(m, kn, zz)
		if (zz = z)
			sc := s
		if (s > tdS)
			{
			tdS := s
			tdZ := zz
			}
		}
	return sc
}

SwTplBest(k, z) {
	SwTplMask(k, m, kn)
	if (!IsObject(m))
		return -9
	return SwTplScore(m, kn, z)
}

SwTplMask(k, ByRef m, ByRef kn) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwBarL, SwBarW, SwFishX, FishBarLeft, SwGrad, SwGradOk, SwGradDef, SwDarkR, SwDarkG, SwDarkB
	m := ""
	kn := ""
	cx := Round(SwSlotX(k)) - Round(FishBarLeft)
	sz := 64 * SwSB
	x0 := cx - sz / 2
	y0 := SwFrTop + 11 * SwSB
	cell := sz / 16
	L := SwBarL - Round(FishBarLeft)
	w := SwBarW
	c := L + w / 2.0
	fx := (SwFishX >= 0) ? SwFishX - Round(FishBarLeft) : -9999
	pG := SwGradOk ? &SwGrad : &SwGradDef
	mm := []
	kk := []
	Loop 256
		{
		mm.Push(0)
		kk.Push(0)
		}
	total := 0
	Loop 16
		{
		j := A_Index - 1
		Loop 16
			{
			i := A_Index - 1
			hit := 0
			kc := 0
			for a, oy in [0.25, 0.75]
				{
				y := Round(y0 + cell * (j + oy))
				if (y < 0 or y >= CaptureH)
					continue
				p := pCaptureBits + y * CaptureW * 4
				for b, ox in [0.25, 0.75]
					{
					x := Round(x0 + cell * (i + ox))
					if (x < 0 or x >= CaptureW)
						continue
					u := (x - L) / (w - 1.0)
					if (Abs(x - c) <= 30 * SwSB or Abs(x - fx) <= 10 * SwSB)
						continue
					if ((u < 0.03 and x >= L - 8 * SwSB) or (u > 0.97 and x <= L + w - 1 + 8 * SwSB))
						continue
					if (u >= 0.03 and u <= 0.97)
						{
						bin := Floor(u * 64)
						if (bin > 63)
							bin := 63
						eb := NumGet(pG + 0, bin * 3, "UChar")
						eg := NumGet(pG + 0, bin * 3 + 1, "UChar")
						er := NumGet(pG + 0, bin * 3 + 2, "UChar")
						}
					else
						{
						er := SwDarkR
						eg := SwDarkG
						eb := SwDarkB
						}
					px := NumGet(p + x * 4, 0, "UInt")
					db := Abs((px & 0xFF) - eb)
					dg := Abs(((px >> 8) & 0xFF) - eg)
					dr := Abs(((px >> 16) & 0xFF) - er)
					d := (db > dg) ? ((db > dr) ? db : dr) : ((dg > dr) ? dg : dr)
					kc++
					if (d >= 40)
						hit++
					}
				}
			if (kc >= 2)
				{
				mm[j * 16 + i + 1] := hit / kc
				kk[j * 16 + i + 1] := 1
				total++
				}
			}
		}
	if (total < 96)
		return
	m := mm
	kn := kk
}

SwTplScore(m, kn, z) {
	global SwTplF, SwTplFBuf
	if (!kn.HasKey("TpCnt"))
		SwTplPrep(m, kn)
	n := kn.TpCnt
	if (n < 16)
		return -9
	sa := kn.TpSumA
	saa := kn.TpSumAA
	best := -9
	if (kn.HasKey("TpPV"))
		{
		VarSetCapacity(sums, 216, 0)
		DllCall(SwTplSumFn(), "Ptr", kn.TpPV, "Ptr", kn.TpPO, "Int", n, "Ptr", &SwTplFBuf + z * 2048, "Ptr", &sums)
		Loop 9
			{
			o := (A_Index - 1) * 24
			sb := NumGet(sums, o, "Double")
			sbb := NumGet(sums, o + 8, "Double")
			sab := NumGet(sums, o + 16, "Double")
			num := sab - sa * sb / n
			den := (saa - sa * sa / n) * (sbb - sb * sb / n)
			if (den <= 0.000001)
				continue
			sc := num / Sqrt(den)
			if (sc > best)
				best := sc
			}
		return best
		}
	cv := kn.TpVals
	base := z * 256 + 1
	Loop 9
		{
		of := kn.TpOffs[A_Index]
		sb := 0
		sbb := 0
		sab := 0
		Loop % n
			{
			vb := SwTplF[base + of[A_Index]]
			va := cv[A_Index]
			sb := sb + vb
			sbb := sbb + vb * vb
			sab := sab + va * vb
			}
		num := sab - sa * sb / n
		den := (saa - sa * sa / n) * (sbb - sb * sb / n)
		if (den <= 0.000001)
			continue
		sc := num / Sqrt(den)
		if (sc > best)
			best := sc
		}
	return best
}

SwTplPrep(m, kn) {
	cv := []
	cj := []
	ci := []
	n := 0
	sa := 0
	saa := 0
	Loop 16
		{
		j := A_Index - 1
		Loop 16
			{
			i := A_Index - 1
			if (!kn[j * 16 + i + 1])
				continue
			va := m[j * 16 + i + 1]
			n++
			sa := sa + va
			saa := saa + va * va
			cv.Push(va)
			cj.Push(j)
			ci.Push(i)
			}
		}
	kn.TpCnt := n
	kn.TpSumA := sa
	kn.TpSumAA := saa
	if (SwTplSumFn())
		{
		kn.SetCapacity("TpBV", n * 8 + 8)
		kn.SetCapacity("TpBO", 9 * n * 4 + 8)
		pv := kn.GetAddress("TpBV")
		po := kn.GetAddress("TpBO")
		Loop % n
			NumPut(cv[A_Index], pv + (A_Index - 1) * 8, 0, "Double")
		q := 0
		Loop 3
			{
			dx := A_Index - 2
			Loop 3
				{
				dy := A_Index - 2
				Loop % n
					{
					NumPut(Mod(cj[A_Index] - dy + 16, 16) * 16 + Mod(ci[A_Index] - dx + 16, 16), po + q * 4, 0, "Int")
					q++
					}
				}
			}
		kn.TpPV := pv
		kn.TpPO := po
		return
		}
	of := []
	Loop 3
		{
		dx := A_Index - 2
		Loop 3
			{
			dy := A_Index - 2
			o := []
			Loop % n
				o.Push(Mod(cj[A_Index] - dy + 16, 16) * 16 + Mod(ci[A_Index] - dx + 16, 16))
			of.Push(o)
			}
		}
	kn.TpVals := cv
	kn.TpOffs := of
}

SwTplSumFn() {
	static pFn := "", Hex := "534C8B5424304531DB4183FB097D5B660F57C0660F57C9660F57D231C04439C07D2E48631A4883C204F2410F101CD9F20F1024C1F20F58C3660F28EBF20F59EBF20F58CDF20F59E3F20F58D4FFC0EBCDF2410F1102F2410F114A08F2410F1152104983C21841FFC3EB9F5BC3"
	if (pFn != "")
		return pFn
	pFn := 0
	if (A_PtrSize != 8)
		return 0
	n := StrLen(Hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(Hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	tn := 20
	VarSetCapacity(tv, tn * 8, 0)
	VarSetCapacity(tofs, 9 * tn * 4, 0)
	VarSetCapacity(ttpl, 256 * 8, 0)
	VarSetCapacity(tout, 216, 0)
	Loop 256
		NumPut(Mod((A_Index - 1) * 13, 255) / 255.0, ttpl, (A_Index - 1) * 8, "Double")
	Loop % tn
		NumPut(Mod((A_Index - 1) * 7, 5) / 4.0, tv, (A_Index - 1) * 8, "Double")
	Loop % 9 * tn
		NumPut(Mod((A_Index - 1) * 37 + 11, 256), tofs, (A_Index - 1) * 4, "Int")
	DllCall(p, "Ptr", &tv, "Ptr", &tofs, "Int", tn, "Ptr", &ttpl, "Ptr", &tout)
	Loop 9
		{
		s := A_Index - 1
		sb := 0
		sbb := 0
		sab := 0
		Loop % tn
			{
			c := A_Index - 1
			vb := NumGet(ttpl, NumGet(tofs, (s * tn + c) * 4, "Int") * 8, "Double")
			va := NumGet(tv, c * 8, "Double")
			sb := sb + vb
			sbb := sbb + vb * vb
			sab := sab + va * vb
			}
		if (NumGet(tout, s * 24, "Double") != sb or NumGet(tout, s * 24 + 8, "Double") != sbb or NumGet(tout, s * 24 + 16, "Double") != sab)
			{
			DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
			return 0
			}
		}
	pFn := p
	return pFn
}

SwTip(now) {
	global SwTipT, SwPhase, SwLit, SwK0, SwOrder, SwClicks, SwStop, SwStopWhy, SwStarsValid, SwStarFound, SwFound, TooltipX, Tooltip13, MgInPlay
	global SwPanelTxt, SwPanelLast
	if (now - SwTipT < 0.25)
		return
	SwTipT := now
	if (!MgInPlay)
		return
	if (!SwStarFound)
		{
		txt := "Stellarwave: stars not found"
		SwPanelTxt := "stars not found"
		}
	else if (!SwPhase)
		{
		txt := "Stellarwave: tracking"
		SwPanelTxt := (SwPanelLast != "") ? SwPanelLast : "waiting for signs"
		}
	else if (SwStop)
		{
		txt := "Stellarwave: stopped (" . SwStopWhy . ")"
		SwPanelLast := "stopped - " . SwStopShort(SwStopWhy)
		SwPanelTxt := SwPanelLast
		}
	else
		{
		txt := "Stellarwave: " . SwLit . "/12 lit, " . SwOrder.Length() . " signs seen" . ((SwLit < 12) ? ", next " . SwZodiac(SwLit) : "")
		SwPanelLast := SwLit . "/12 lit" . ((SwLit < 12) ? ", next " . SwZodiac(SwLit) : "")
		SwPanelTxt := SwPanelLast
		}
	tooltip, %txt%, %TooltipX%, %Tooltip13%, 13
}

; short, plain reason for the info panel
SwStopShort(why) {
	if (InStr(why, "cursor"))
		return "cursor moved"
	if (InStr(why, "shape veto"))
		return "sign looked wrong"
	if (InStr(why, "tie unresolved"))
		return "signs too close"
	if (InStr(why, "click failed") or InStr(why, "white"))
		return "click missed"
	if (InStr(why, "already clicked"))
		return "order mixed up"
	if (InStr(why, "lit") or InStr(why, "k0"))
		return "stars misread"
	if (InStr(why, "gap"))
		return "macro lagged"
	if (InStr(why, "auto retry"))
		return "auto retry out of signs"
	return why
}

RodTol(v) {
	if v is not number
		return 20
	v := Round(v)
	if (v < 0)
		return 0
	if (v > 255)
		return 255
	return v
}

RodCap(o, k, other, t) {
	i := 1
	while (i <= other.n and i <= 9)
		{
		d := Abs(o.r[k] - other.r[i])
		dg := Abs(o.g[k] - other.g[i])
		db := Abs(o.b[k] - other.b[i])
		if (dg > d)
			d := dg
		if (db > d)
			d := db
		c := (d = 0) ? -1 : (d - 1) // 2
		if (c < t)
			t := c
		i++
		}
	return t
}

PcPrmAt(a, r, g, b, tol, mode) {
	NumPut(b, a + 0, 0, "Int")
	NumPut(g, a + 0, 4, "Int")
	NumPut(r, a + 0, 8, "Int")
	NumPut(tol, a + 0, 12, "Int")
	NumPut(mode, a + 0, 16, "Int")
	NumPut(0, a + 0, 20, "Int")
	NumPut(b, a + 0, 24, "Int")
	NumPut(g, a + 0, 28, "Int")
	NumPut(r, a + 0, 32, "Int")
	NumPut(tol, a + 0, 36, "Int")
	NumPut(mode, a + 0, 40, "Int")
	NumPut(1, a + 0, 44, "Int")
}

PcFindAt(p, n, stride, a) {
	if (n <= 0)
		return -1
	pFn := PcFindPixFn()
	if (pFn)
		return DllCall(pFn, "Ptr", p, "Int", n, "Int", stride, "Ptr", a, "Int")
	return PcFindPixAhk(p, n, stride, NumGet(a + 0, 0, "Int"), NumGet(a + 0, 4, "Int"), NumGet(a + 0, 8, "Int"), NumGet(a + 0, 12, "Int"), NumGet(a + 0, 16, "Int"), NumGet(a + 0, 20, "Int"))
}

TryRowRunsAt(p, a, gap, rr) {
	global CaptureW
	x := 0
	n := 0
	s0 := -1
	e0 := -1
	while (x < CaptureW and n < 40)
		{
		s := PcFindAt(p + x * 4, CaptureW - x, 4, a)
		if (s < 0)
			break
		s += x
		e := PcFindAt(p + (s + 1) * 4, CaptureW - s - 1, 4, a + 24)
		e := (e < 0) ? CaptureW - 1 : s + e
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

TryRunsMerge(rr, gap) {
	j := 2
	while (j <= rr.Length())
		{
		v := rr[j]
		k := j - 1
		while (k >= 1 and rr[k][1] > v[1])
			{
			rr[k + 1] := rr[k]
			k--
			}
		rr[k + 1] := v
		j++
		}
	out := []
	for i, v in rr
		{
		n := out.Length()
		if (n and v[1] - out[n][2] - 1 <= gap)
			{
			if (v[2] > out[n][2])
				out[n][2] := v[2]
			}
		else
			out.Push([v[1], v[2]])
		}
	if (rr.Length())
		rr.RemoveAt(1, rr.Length())
	for i, v in out
		rr.Push(v)
}

TryFishLineAt(c, k) {
	global pCaptureBits, CaptureW, CaptureH
	if (c < 0 or c >= CaptureW)
		return false
	n := 0
	for i, y in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		p := pCaptureBits + y * CaptureW * 4
		v := NumGet(p + c * 4, 0, "UInt")
		a := (c - k >= 0) ? NumGet(p + (c - k) * 4, 0, "UInt") : -1
		b := (c + k < CaptureW) ? NumGet(p + (c + k) * 4, 0, "UInt") : -1
		if (a < 0)
			a := b
		if (b < 0)
			b := a
		if (a < 0)
			continue
		d := 0
		for j, sh in [0, 8, 16]
			{
			e := Abs(((v >> sh) & 0xFF) - ((((a >> sh) & 0xFF) + ((b >> sh) & 0xFF)) / 2))
			if (e > d)
				d := e
			}
		if (d >= 8)
			n++
		}
	return (n >= 2)
}

TryTrackAtX(x) {
	global pCaptureBits, CaptureW, CaptureH, TryhardTrackColors, TryhardTrackTol
	if (x < 0 or x >= CaptureW)
		return false
	tkL := ColorListParse(TryhardTrackColors)
	tkT := RodTol(TryhardTrackTol)
	tkN := 0
	for tkI, tkY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tkPx := NumGet(pCaptureBits + (tkY * CaptureW + x) * 4, 0, "UInt")
		tkB := tkPx & 0xFF
		tkG := (tkPx >> 8) & 0xFF
		tkR := (tkPx >> 16) & 0xFF
		if ((tkR + 16 >= tkB and tkR < 70 and tkB < 70 and (tkG < 40 or (tkG < 48 and tkR >= tkG))) or ColorListHitPx(tkL, tkPx, tkT))
			tkN++
		}
	return (tkN >= 2)
}


MiguBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global MiguBarScanned, MiguBarFound, MiguBarL, MiguBarW
	if (MiguBarScanned)
		return MiguBarFound
	MiguBarScanned := true
	MiguBarFound := false
	if (CaptureW < 40 or CaptureH < 6)
		return false
	qRows := [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
	qTrk := 0
	qOff := qRows[2] * CaptureW * 4
	qX := 0
	while (qX < CaptureW)
		{
		qP := NumGet(pCaptureBits + 0, qOff + (qX*4), "UInt")
		qB := qP & 0xFF
		qG := (qP >> 8) & 0xFF
		qR := (qP >> 16) & 0xFF
		if (qR > 150 and qG < 110 and (qR - qG) > 90 and (qR - qB) > 55)
			qTrk++
		qX++
		}
	if (qTrk < CaptureW * 0.25)
		return false
	VarSetCapacity(qHits, CaptureW, 0)
	for qI, qY in qRows
		{
		qOff := qY * CaptureW * 4
		qX := 0
		while (qX < CaptureW)
			{
			qP := NumGet(pCaptureBits + 0, qOff + (qX*4), "UInt")
			qB := qP & 0xFF
			qG := (qP >> 8) & 0xFF
			qR := (qP >> 16) & 0xFF
			if (qR > 190 and qG >= 140 and qG <= 245 and qB >= 90 and qB <= 215 and (qR - qB) > 40)
				NumPut(NumGet(qHits, qX, "UChar") + 1, qHits, qX, "UChar")
			qX++
			}
		}
	qGap := Round(CaptureW * 0.035)
	if (qGap < 12)
		qGap := 12
	qMinW := Round(CaptureW * 0.05)
	if (qMinW < 24)
		qMinW := 24
	qBestL := -1
	qBestLen := 0
	qRunS := -1
	qLast := -1
	qX := 0
	while (qX <= CaptureW)
		{
		qOn := false
		if (qX < CaptureW)
			qOn := (NumGet(qHits, qX, "UChar") >= 2)
		if (qOn)
			{
			if (qRunS < 0)
				qRunS := qX
			qLast := qX
			}
		else if (qRunS >= 0 and ((qX - qLast) > qGap or qX = CaptureW))
			{
			if ((qLast - qRunS + 1) > qBestLen)
				{
				qBestLen := qLast - qRunS + 1
				qBestL := qRunS
				}
			qRunS := -1
			}
		qX++
		}
	if (qBestL < 0 or qBestLen < qMinW or qBestLen > CaptureW * 0.85)
		return false
	MiguBarL := FishBarLeft + qBestL
	MiguBarW := qBestLen
	MiguBarFound := true
	return true
}

MiguScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, FishColor, FishBarColorTolerance
	global MiguFishX, MiguLastX, MiguScanned, MiguFound
	if (MiguScanned)
		return MiguFound
	MiguScanned := true
	MiguFound := false
	MiguFishX := -1
	if (CaptureW < 40 or CaptureH < 6)
		return false

	gkRows := [Floor(CaptureH * 0.30), Floor(CaptureH * 0.55), Floor(CaptureH * 0.85)]
	VarSetCapacity(gkBuf, CaptureW, 0)
	for gkI, gkY in gkRows
		{
		gkOff := gkY * CaptureW * 4
		gkX := 0
		while (gkX < CaptureW)
			{
			gkP := NumGet(pCaptureBits + 0, gkOff + (gkX*4), "UInt")
			if (((gkP >> 16) & 0xFF) < 110 and ((gkP >> 8) & 0xFF) < 35 and (gkP & 0xFF) < 40)
				NumPut(1, gkBuf, gkX, "UChar")
			gkX++
			}
		}
	gkMinW := Round(CaptureW * 0.005)
	if (gkMinW < 3)
		gkMinW := 3
	gkMaxW := Round(CaptureW * 0.034)
	if (gkMaxW < 12)
		gkMaxW := 12
	gkGap := Round(CaptureW * 0.006)
	if (gkGap < 3)
		gkGap := 3
	gkPad := Round(CaptureW * 0.004)
	if (gkPad < 2)
		gkPad := 2
	VarSetCapacity(gkMask, CaptureW, 0)
	gkX := 0
	while (gkX < CaptureW)
		{
		if (!NumGet(gkBuf, gkX, "UChar"))
			{
			gkX++
			continue
			}
		gkA := gkX
		gkLast := gkX
		while (gkX < CaptureW and (NumGet(gkBuf, gkX, "UChar") or (gkX - gkLast) <= gkGap))
			{
			if (NumGet(gkBuf, gkX, "UChar"))
				gkLast := gkX
			gkX++
			}
		gkW := gkLast - gkA + 1
		if (gkW < gkMinW or gkW > gkMaxW)
			continue
		gkM := gkA - gkPad
		if (gkM < 0)
			gkM := 0
		while (gkM <= gkLast + gkPad and gkM < CaptureW)
			{
			NumPut(1, gkMask, gkM, "UChar")
			gkM++
			}
		}

	gkList := ColorListParse(FishColor)
	if (gkList.n < 1)
		return false
	gkTol := FishBarColorTolerance
	if (gkTol < 6)
		gkTol := 6
	gkMinR := 255
	gkMinG := 255
	gkI := 1
	while (gkI <= gkList.n)
		{
		if (gkList.r[gkI] < gkMinR)
			gkMinR := gkList.r[gkI]
		if (gkList.g[gkI] < gkMinG)
			gkMinG := gkList.g[gkI]
		gkI++
		}
	gkMinR := gkMinR - gkTol
	gkMinG := gkMinG - gkTol
	gkFRows := []
	Loop, 5
		{
		gkY := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (gkY >= CaptureH)
			gkY := CaptureH - 1
		gkFRows.Push(gkY)
		}
	gkFW := Round(CaptureW * 0.03)
	if (gkFW < 8)
		gkFW := 8
	gkCandX := []
	gkCandV := []
	for gkPass, gkRi in [3, 2, 4]
		{
		gkOff := gkFRows[gkRi] * CaptureW * 4
		gkS := -1
		gkX := 0
		while (gkX <= CaptureW)
			{
			gkHit := false
			if (gkX < CaptureW and !NumGet(gkMask, gkX, "UChar"))
				{
				gkP := NumGet(pCaptureBits + 0, gkOff + (gkX*4), "UInt")
				if (((gkP >> 16) & 0xFF) >= gkMinR and ((gkP >> 8) & 0xFF) >= gkMinG)
					gkHit := ColorListHitPx(gkList, gkP, gkTol)
				}
			if (gkHit)
				{
				if (gkS < 0)
					gkS := gkX
				}
			else if (gkS >= 0)
				{
				gkRw := gkX - gkS
				if (gkRw >= 2 and gkRw <= gkFW)
					{
					gkCx := gkS + (gkRw // 2)
					gkV := 0
					for gkI, gkY in gkFRows
						{
						if (MiguFishAt(gkCx, gkY, gkList, gkTol, &gkMask))
							gkV++
						}
					if (gkV >= 4)
						{
						gkCandX.Push(gkCx)
						gkCandV.Push(gkV)
						}
					}
				gkS := -1
				}
			gkX++
			}
		if (gkCandX.MaxIndex())
			break
		}
	if (!gkCandX.MaxIndex())
		return false
	gkBestV := 0
	for gkI, gkV in gkCandV
		{
		if (gkV > gkBestV)
			gkBestV := gkV
		}
	gkBestX := -1
	gkNear := 999999
	for gkI, gkCx in gkCandX
		{
		if (gkCandV[gkI] < gkBestV)
			continue
		if (MiguLastX >= 0)
			{
			gkD := Abs((FishBarLeft + gkCx) - MiguLastX)
			if (gkD < gkNear and gkD <= CaptureW * 0.25)
				{
				gkNear := gkD
				gkBestX := gkCx
				}
			}
		}
	if (gkBestX < 0)
		{
		for gkI, gkCx in gkCandX
			{
			if (gkCandV[gkI] >= gkBestV and (gkBestX < 0 or gkCx < gkBestX))
				gkBestX := gkCx
			}
		}
	MiguFishX := FishBarLeft + gkBestX
	MiguLastX := MiguFishX
	MiguFound := true
	return true
}

MiguFishAt(fx, fy, fList, fTol, pMask) {
	global pCaptureBits, CaptureW, CaptureH
	if (fy < 0 or fy >= CaptureH)
		return false
	fOff := fy * CaptureW * 4
	fI := fx - 5
	if (fI < 0)
		fI := 0
	fE := fx + 5
	if (fE > CaptureW - 1)
		fE := CaptureW - 1
	while (fI <= fE)
		{
		if (!NumGet(pMask + 0, fI, "UChar") and ColorListHitPx(fList, NumGet(pCaptureBits + 0, fOff + (fI*4), "UInt"), fTol))
			return true
		fI++
		}
	return false
}

CastboundScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global CastBarL, CastBarW, CastFishX, CastScanned, CastFound
	global CastPrevL, CastPrevW, CastPrevF, CastSameN, CastSameT, CastStatic, QpcFreq
	global CastboundBarColors, CastboundFishColors, CastboundTrackColors
	if ((CastboundBarColors != "" or CastboundFishColors != "" or CastboundTrackColors != "")
		and CastboundXActive())
		return CastboundScanX()
	if (CastScanned)
		return CastFound
	CastScanned := true
	CastFound := false
	CastBarL := -1
	CastBarW := 0
	CastFishX := -1
	if (CaptureW < 80 or CaptureH < 6)
		return false

	row := CaptureH // 2
	rowOffset := row * CaptureW * 4

	; --- is the minigame even on screen? ----------------------------------------------------
	nTrk := 0
	trkFirst := -1
	trkLast := -1
	x := 0
	while (x < CaptureW)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		tb := px & 0xFF
		tg := (px >> 8) & 0xFF
		tr := (px >> 16) & 0xFF
		tsum := tb + tg + tr
		if ((tb - tg) > 20 and (tr - tg) > 5 and tsum >= 180 and tsum <= 340)
			{
			nTrk++
			if (trkFirst < 0)
				trkFirst := x
			trkLast := x
			}
		x++
		}
	if (nTrk < CaptureW * 0.10)
		return false
	if ((trkLast - trkFirst + 1) < CaptureW * 0.45)
		{
		return false
		}

	cbY1 := CaptureH // 3
	cbY2 := CaptureH // 2
	cbY3 := (CaptureH * 2) // 3
	cbGapMax := Round(CaptureW * 0.035)
	if (cbGapMax < 30)
		cbGapMax := 30
	bestL := -1
	bestLen := 0
	runS := -1
	runE := -1
	gap := 0
	cbX := 0
	while (cbX < CaptureW)
		{
		cbHits := 0
		for cbK, cbYY in [cbY1, cbY2, cbY3]
			{
			px := NumGet(pCaptureBits + 0, (cbYY*CaptureW*4) + (cbX*4), "UInt")
			cbB := px & 0xFF
			cbG := (px >> 8) & 0xFF
			cbR := (px >> 16) & 0xFF
			cbSum := cbB + cbG + cbR
			cbIsTrk := ((cbB - cbG) > 20 and (cbR - cbG) > 5 and cbSum >= 180 and cbSum <= 340)
			cbIsSw := (cbG < 90 and cbB > 130 and (cbB - cbG) > 80 and cbR < 160)
			if (!cbIsTrk and !cbIsSw and cbSum >= 110)
				cbHits++
			}
		if (cbHits >= 2)
			{
			if (runS < 0)
				runS := cbX
			runE := cbX
			gap := 0
			}
		else if (runS >= 0)
			{
			gap++
			if (gap > cbGapMax)
				{
				if (runE - runS + 1 > bestLen)
					{
					bestLen := runE - runS + 1
					bestL := runS
					}
				runS := -1
				gap := 0
				}
			}
		cbX++
		}
	if (runS >= 0 and (runE - runS + 1) > bestLen)
		{
		bestLen := runE - runS + 1
		bestL := runS
		}
	if (bestL >= 0 and bestLen >= 24 and bestLen <= CaptureW * 0.85)
		{
		CastBarL := FishBarLeft + bestL
		CastBarW := bestLen
		}

	; --- fallback: the gap the bar leaves in the purple track --------------------------------
	if (CastBarW <= 0)
		{
		tGap := Round(CaptureW * 0.02)
		if (tGap < 10)
			tGap := 10
		nTrk := 0
		tBest := -1
		tLen := 0
		tRun := -1
		tEnd := -1
		tG := 0
		x := 0
		while (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			sum := bb + gg + rr
			isTrk := ((bb - gg) > 20 and (rr - gg) > 5 and sum >= 180 and sum <= 340)
			if (isTrk)
				{
				nTrk++
				if (tRun >= 0)
					{
					tG++
					if (tG > tGap)
						{
						if (tEnd - tRun + 1 > tLen)
							{
							tLen := tEnd - tRun + 1
							tBest := tRun
							}
						tRun := -1
						tG := 0
						}
					}
				}
			else
				{
				if (tRun < 0)
					tRun := x
				tEnd := x
				tG := 0
				}
			x++
			}
		if (tRun >= 0 and (tEnd - tRun + 1) > tLen)
			{
			tLen := tEnd - tRun + 1
			tBest := tRun
			}
		if (nTrk >= CaptureW * 0.25 and tBest >= 0 and tLen >= CaptureW * 0.05 and tLen <= CaptureW * 0.9)
			{
			CastBarL := FishBarLeft + tBest
			CastBarW := tLen
			}
		}

	; --- the sword marker: deep violet, almost no green --------------------------------------
	y1 := CaptureH // 6
	y2 := CaptureH // 2
	y3 := (CaptureH * 5) // 6
	sBest := -1
	sLen := 0
	sRun := -1
	sPrev := -1
	sGap := 0
	x := 0
	while (x < CaptureW)
		{
		hits := 0
		for i, yy in [y1, y2, y3]
			{
			px := NumGet(pCaptureBits + 0, (yy*CaptureW*4) + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			if (gg < 90 and bb > 130 and (bb - gg) > 80 and rr < 160)
				hits++
			}
		if (hits >= 2)
			{
			if (sRun < 0)
				sRun := x
			sPrev := x
			sGap := 0
			}
		else if (sRun >= 0)
			{
			sGap++
			if (sGap > 6)
				{
				if ((sPrev - sRun + 1) > sLen)
					{
					sLen := sPrev - sRun + 1
					sBest := (sRun + sPrev) // 2
					}
				sRun := -1
				sGap := 0
				}
			}
		x++
		}
	if (sRun >= 0 and (sPrev - sRun + 1) > sLen)
		{
		sLen := sPrev - sRun + 1
		sBest := (sRun + sPrev) // 2
		}
	if (sBest >= 0 and sLen >= 6)
		CastFishX := FishBarLeft + sBest

	DllCall("QueryPerformanceCounter", "Int64*", csNow)
	if (CastBarW > 0 and CastBarL = CastPrevL and CastBarW = CastPrevW and CastFishX = CastPrevF)
		{
		CastSameN := CastSameN + 1
		if (!CastSameT)
			CastSameT := csNow
		}
	else
		{
		CastSameN := 0
		CastSameT := 0
		}
	CastPrevL := CastBarL
	CastPrevW := CastBarW
	CastPrevF := CastFishX
	CastStatic := (CastSameT and ((csNow - CastSameT) / QpcFreq) >= 0.25)

	CastFound := (CastBarW > 0 and CastFishX >= 0)
	return CastFound
}

CastboundScanX() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global CastBarL, CastBarW, CastFishX, CastScanned, CastFound
	global CastPrevL, CastPrevW, CastPrevF, CastSameN, CastSameT, CastStatic, QpcFreq
	global CastboundBarColors, CastboundBarTol, CastboundFishColors, CastboundFishTol, CastboundTrackColors, CastboundTrackTol
	global CbxKey, CbxR, CbxG, CbxB
	cxKey := CastboundBarColors . "|" . CastboundBarTol . "|" . CastboundFishColors . "|" . CastboundFishTol . "|" . CastboundTrackColors . "|" . CastboundTrackTol
	if (cxKey != CbxKey)
		{
		CbxKey := cxKey
		RodLut(CbxR, CbxG, CbxB, CastboundBarColors, CastboundBarTol, CastboundSwordX(), CastboundFishTol, CastboundTrackColors, CastboundTrackTol)
		}
	if (CastScanned)
		return CastFound
	CastScanned := true
	CastFound := false
	CastBarL := -1
	CastBarW := 0
	CastFishX := -1
	if (CaptureW < 80 or CaptureH < 6)
		return false

	row := CaptureH // 2
	rowOffset := row * CaptureW * 4

	; --- is the minigame even on screen? ----------------------------------------------------
	nTrk := 0
	trkFirst := -1
	trkLast := -1
	x := 0
	while (x < CaptureW)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		tb := px & 0xFF
		tg := (px >> 8) & 0xFF
		tr := (px >> 16) & 0xFF
		tsum := tb + tg + tr
		cxH := CbxR[tr] & CbxG[tg] & CbxB[tb]
		if (((tb - tg) > 20 and (tr - tg) > 5 and tsum >= 180 and tsum <= 340) or (cxH & 0x7FC0000))
			{
			nTrk++
			if (trkFirst < 0)
				trkFirst := x
			trkLast := x
			}
		x++
		}
	if (nTrk < CaptureW * 0.10)
		return false
	if ((trkLast - trkFirst + 1) < CaptureW * 0.45)
		return false

	cbY1 := CaptureH // 3
	cbY2 := CaptureH // 2
	cbY3 := (CaptureH * 2) // 3
	cbGapMax := Round(CaptureW * 0.035)
	if (cbGapMax < 30)
		cbGapMax := 30
	bestL := -1
	bestLen := 0
	runS := -1
	runE := -1
	gap := 0
	cbX := 0
	while (cbX < CaptureW)
		{
		cbHits := 0
		for cbK, cbYY in [cbY1, cbY2, cbY3]
			{
			px := NumGet(pCaptureBits + 0, (cbYY*CaptureW*4) + (cbX*4), "UInt")
			cbB := px & 0xFF
			cbG := (px >> 8) & 0xFF
			cbR := (px >> 16) & 0xFF
			cbSum := cbB + cbG + cbR
			cxH := CbxR[cbR] & CbxG[cbG] & CbxB[cbB]
			cbIsTrk := (((cbB - cbG) > 20 and (cbR - cbG) > 5 and cbSum >= 180 and cbSum <= 340) or (cxH & 0x7FC0000))
			cbIsSw := ((cbG < 90 and cbB > 130 and (cbB - cbG) > 80 and cbR < 160) or (cxH & 0x3FE00))
			if (!cbIsTrk and !cbIsSw and (cbSum >= 110 or (cxH & 0x1FF)))
				cbHits++
			}
		if (cbHits >= 2)
			{
			if (runS < 0)
				runS := cbX
			runE := cbX
			gap := 0
			}
		else if (runS >= 0)
			{
			gap++
			if (gap > cbGapMax)
				{
				if (runE - runS + 1 > bestLen)
					{
					bestLen := runE - runS + 1
					bestL := runS
					}
				runS := -1
				gap := 0
				}
			}
		cbX++
		}
	if (runS >= 0 and (runE - runS + 1) > bestLen)
		{
		bestLen := runE - runS + 1
		bestL := runS
		}
	if (bestL >= 0 and bestLen >= 24 and bestLen <= CaptureW * 0.85)
		{
		CastBarL := FishBarLeft + bestL
		CastBarW := bestLen
		}

	; --- fallback: the gap the bar leaves in the purple track --------------------------------
	if (CastBarW <= 0)
		{
		tGap := Round(CaptureW * 0.02)
		if (tGap < 10)
			tGap := 10
		nTrk := 0
		tBest := -1
		tLen := 0
		tRun := -1
		tEnd := -1
		tG := 0
		x := 0
		while (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			sum := bb + gg + rr
			cxH := CbxR[rr] & CbxG[gg] & CbxB[bb]
			isTrk := (((bb - gg) > 20 and (rr - gg) > 5 and sum >= 180 and sum <= 340) or (cxH & 0x7FC0000))
			if (isTrk)
				{
				nTrk++
				if (tRun >= 0)
					{
					tG++
					if (tG > tGap)
						{
						if (tEnd - tRun + 1 > tLen)
							{
							tLen := tEnd - tRun + 1
							tBest := tRun
							}
						tRun := -1
						tG := 0
						}
					}
				}
			else
				{
				if (tRun < 0)
					tRun := x
				tEnd := x
				tG := 0
				}
			x++
			}
		if (tRun >= 0 and (tEnd - tRun + 1) > tLen)
			{
			tLen := tEnd - tRun + 1
			tBest := tRun
			}
		if (nTrk >= CaptureW * 0.25 and tBest >= 0 and tLen >= CaptureW * 0.05 and tLen <= CaptureW * 0.9)
			{
			CastBarL := FishBarLeft + tBest
			CastBarW := tLen
			}
		}

	; --- the sword marker: deep violet, almost no green --------------------------------------
	y1 := CaptureH // 6
	y2 := CaptureH // 2
	y3 := (CaptureH * 5) // 6
	sBest := -1
	sLen := 0
	sRun := -1
	sPrev := -1
	sGap := 0
	x := 0
	while (x < CaptureW)
		{
		hits := 0
		for i, yy in [y1, y2, y3]
			{
			px := NumGet(pCaptureBits + 0, (yy*CaptureW*4) + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			cxH := CbxR[rr] & CbxG[gg] & CbxB[bb]
			if ((cxH & 0x3FE00) or (gg < 90 and bb > 130 and (bb - gg) > 80 and rr < 160))
				hits++
			}
		if (hits >= 2)
			{
			if (sRun < 0)
				sRun := x
			sPrev := x
			sGap := 0
			}
		else if (sRun >= 0)
			{
			sGap++
			if (sGap > 6)
				{
				if ((sPrev - sRun + 1) > sLen)
					{
					sLen := sPrev - sRun + 1
					sBest := (sRun + sPrev) // 2
					}
				sRun := -1
				sGap := 0
				}
			}
		x++
		}
	if (sRun >= 0 and (sPrev - sRun + 1) > sLen)
		{
		sLen := sPrev - sRun + 1
		sBest := (sRun + sPrev) // 2
		}
	if (sBest >= 0 and sLen >= 6)
		CastFishX := FishBarLeft + sBest

	DllCall("QueryPerformanceCounter", "Int64*", csNow)
	if (CastBarW > 0 and CastBarL = CastPrevL and CastBarW = CastPrevW and CastFishX = CastPrevF)
		{
		CastSameN := CastSameN + 1
		if (!CastSameT)
			CastSameT := csNow
		}
	else
		{
		CastSameN := 0
		CastSameT := 0
		}
	CastPrevL := CastBarL
	CastPrevW := CastBarW
	CastPrevF := CastFishX
	CastStatic := (CastSameT and ((csNow - CastSameT) / QpcFreq) >= 0.25)

	CastFound := (CastBarW > 0 and CastFishX >= 0)
	return CastFound
}

CastboundXActive() {
	global CastboundBarColors, CastboundBarTol, CastboundFishColors, CastboundFishTol, CastboundTrackColors, CastboundTrackTol
	static key := "", act := false
	k := CastboundBarColors . "|" . CastboundBarTol . "|" . CastboundFishColors . "|" . CastboundFishTol . "|" . CastboundTrackColors . "|" . CastboundTrackTol
	if (k == key)
		return act
	key := k
	act := false
	for li, lst in [[ColorListParse(CastboundBarColors), RodTol(CastboundBarTol), 1], [ColorListParse(CastboundSwordX()), RodTol(CastboundFishTol), 2], [ColorListParse(CastboundTrackColors), RodTol(CastboundTrackTol), 3]]
		{
		o := lst[1]
		t := lst[2]
		i := 1
		while (i <= o.n and i <= 9)
			{
			r0 := (o.r[i] - t < 0) ? 0 : o.r[i] - t
			g0 := (o.g[i] - t < 0) ? 0 : o.g[i] - t
			b0 := (o.b[i] - t < 0) ? 0 : o.b[i] - t
			r1 := (o.r[i] + t > 255) ? 255 : o.r[i] + t
			g1 := (o.g[i] + t > 255) ? 255 : o.g[i] + t
			b1 := (o.b[i] + t > 255) ? 255 : o.b[i] + t
			if (lst[3] = 1)
				red := (r0 + g0 + b0 >= 110)
			else if (lst[3] = 2)
				red := (g1 < 90 and b0 > 130 and b0 - g1 > 80 and r1 < 160)
			else
				red := (b0 - g1 > 20 and r0 - g1 > 5 and r0 + g0 + b0 >= 180 and r1 + g1 + b1 <= 340)
			if (!red)
				{
				act := true
				return act
				}
			i++
			}
		}
	return act
}

CastboundSwordX() {
	global CastboundFishColors
	static inp := "", outp := ""
	if (CastboundFishColors == inp)
		return outp
	inp := CastboundFishColors
	outp := ""
	Loop, Parse, inp, `,;| , %A_Space%%A_Tab%
		{
		v := ColNorm(A_LoopField)
		if (v < 0 or v = 0x5522A3)
			continue
		outp .= (outp = "" ? "" : ", ") . Format("0x{:06X}", v)
		}
	return outp
}

RodLut(ByRef lr, ByRef lg, ByRef lb, bar, barTol, fish, fishTol, trk, trkTol) {
	lr := []
	lg := []
	lb := []
	v := 0
	while (v < 256)
		{
		lr[v] := 0
		lg[v] := 0
		lb[v] := 0
		v++
		}
	oB := ColorListParse(bar)
	oF := ColorListParse(fish)
	oT := ColorListParse(trk)
	for li, lst in [[oB, RodTol(barTol), 0, oF, oT], [oF, RodTol(fishTol), 9, oT, oT], [oT, RodTol(trkTol), 18, oF, oF]]
		{
		o := lst[1]
		sh := lst[3]
		k := 1
		while (k <= o.n and k <= 9)
			{
			t := RodCap(o, k, lst[5], RodCap(o, k, lst[4], lst[2]))
			bit := 1 << (sh + k - 1)
			v := 0
			while (v < 256)
				{
				if (Abs(v - o.r[k]) <= t)
					lr[v] := lr[v] | bit
				if (Abs(v - o.g[k]) <= t)
					lg[v] := lg[v] | bit
				if (Abs(v - o.b[k]) <= t)
					lb[v] := lb[v] | bit
				v++
				}
			k++
			}
		}
}


BarLiveOk(px, po, tol, prev) {
	if (po < 0)
		return prev
	if (Abs(((px >> 16) & 0xFF) - ((po >> 16) & 0xFF)) <= tol and Abs(((px >> 8) & 0xFF) - ((po >> 8) & 0xFF)) <= tol and Abs((px & 0xFF) - (po & 0xFF)) <= tol)
		return -1
	return px
}

BarOneColor(px) {
	o := {n: 1, r: [(px >> 16) & 0xFF], g: [(px >> 8) & 0xFF], b: [px & 0xFF]}
	return o
}

BarPixAt(x, y) {
	global pCaptureBits, CaptureW, CaptureH
	if (x < 0 or x >= CaptureW or y < 0 or y >= CaptureH)
		return -1
	return NumGet(pCaptureBits + 0, (y*CaptureW*4) + (x*4), "UInt") & 0xFFFFFF
}

BarByTrackContrast(row, ByRef bl, ByRef bw) {
	global CaptureH, FishBarLeft
	bl := -1
	bw := 0
	if (!TrackRunAt(row, s0, e0))
		return false
	w0 := e0 - s0 + 1
	slack := Round(w0 * 0.06)
	if (slack < 6)
		slack := 6
	dy := Round(CaptureH * 0.15)
	if (dy < 2)
		dy := 2
	for i, sgn in [-1, 1]
		{
		ry := row + (sgn * dy)
		if (ry < 1)
			ry := 1
		if (ry > CaptureH - 2)
			ry := CaptureH - 2
		if (ry = row)
			continue
		if (!TrackRunAt(ry, s1, e1) or Abs(s1 - s0) > slack or Abs(e1 - e0) > slack)
			return false
		}
	bl := FishBarLeft + s0
	bw := w0
	return true
}

TrackRunAt(row, ByRef rs, ByRef re) {
	global pCaptureBits, CaptureW, CaptureH
	rs := -1
	re := -1
	if (row < 0 or row >= CaptureH or CaptureW < 40)
		return false
	rowOff := row * CaptureW * 4
	VarSetCapacity(tcHist, 64 * 4, 0)
	x := 0
	while (x < CaptureW)
		{
		px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
		v := ((((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3) // 4)
		NumPut(NumGet(tcHist, v*4, "UInt") + 1, tcHist, v*4, "UInt")
		x++
		}
	half := CaptureW // 2
	acc := 0
	med := 0
	b := 0
	while (b < 64)
		{
		acc += NumGet(tcHist, b*4, "UInt")
		if (acc >= half)
			{
			med := (b * 4) + 2
			break
			}
		b++
		}
	thr := med * 2
	if (thr < med + 15)
		thr := med + 15
	bestLen := 0
	bestS := -1
	runS := -1
	runE := -1
	x := 0
	while (x <= CaptureW)
		{
		on := false
		if (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
			on := ((((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3) > thr)
			}
		if (on)
			{
			if (runS < 0)
				runS := x
			runE := x
			}
		else if (runS >= 0 and ((x - runE) > 20 or x = CaptureW))
			{
			if ((runE - runS + 1) > bestLen)
				{
				bestLen := runE - runS + 1
				bestS := runS
				}
			runS := -1
			}
		x++
		}
	if (bestS < 0 or bestLen < 40)
		return false
	rs := bestS
	re := bestS + bestLen - 1
	return true
}

BarEndInside(row, x, dir) {
	global pCaptureBits, CaptureW, CaptureH
	if (row < 0 or row >= CaptureH)
		return false
	xo := x + (dir * 10)
	xi := x - (dir * 18)
	if (xo < 0 or xo >= CaptureW or xi < 0 or xi >= CaptureW)
		return false
	rowOffset := row * CaptureW * 4
	po := NumGet(pCaptureBits + 0, rowOffset + (xo*4), "UInt")
	pi := NumGet(pCaptureBits + 0, rowOffset + (xi*4), "UInt")
	if (Abs(((po >> 16) & 0xFF) - ((pi >> 16) & 0xFF)) > 40)
		return false
	if (Abs(((po >> 8) & 0xFF) - ((pi >> 8) & 0xFF)) > 40)
		return false
	if (Abs((po & 0xFF) - (pi & 0xFF)) > 40)
		return false
	return true
}

BarColRef() {
	global BarColRing
	if (!IsObject(BarColRing) or BarColRing.MaxIndex() < 3)
		return 0
	return MedianOf(BarColRing)
}

FindBarByColor() {
	global BarLeftColor, BarRightColor, BarColorTolerance, RunLeft, RunWidth, BarScanRow, BarColRing, BarColT, QpcFreq
	global CaptureH, CaptureW, FishBarLeft, LastBarL, LastBarR
	global BarLiveL, BarLiveR, BarLiveMiss, BarWLive, BarLiveOnlyAt, MgInPlay
	if (BarLeftColor = "" or BarRightColor = "")
		return false
	row := BarScanRow
	if (row < 0 or row >= CaptureH)
		row := CaptureH // 2
	lList := ColorListParse(BarLeftColor)
	rList := ColorListParse(BarRightColor)
	if (lList.n < 1 or rList.n < 1)
		return false

	adTol := BarColorTolerance + 24
	lLive := (MgInPlay and BarLiveL >= 0) ? BarOneColor(BarLiveL) : 0
	rLive := (MgInPlay and BarLiveR >= 0) ? BarOneColor(BarLiveR) : 0

	l := -1
	r := -1
	if (LastBarL >= 0)
		{
		lx := Round(LastBarL - FishBarLeft)
		if (lLive)
			l := ColorListFirstX(lLive, adTol, row, lx - 70, lx + 70)
		if (l < 0)
			l := ColorListFirstX(lList, BarColorTolerance, row, lx - 70, lx + 70)
		}
	if (LastBarR >= 0)
		{
		rx := Round(LastBarR - FishBarLeft)
		if (rLive)
			r := ColorListLastX(rLive, adTol, row, rx - 70, rx + 70)
		if (r < 0)
			r := ColorListLastX(rList, BarColorTolerance, row, rx - 70, rx + 70)
		}
	if (l < 0)
		l := ColorListFirstX(lList, BarColorTolerance, row, 0, CaptureW - 1)
	if (r < 0)
		r := ColorListLastX(rList, BarColorTolerance, row, 0, CaptureW - 1)

	if (l < 0 or r < 0)
		{
		Loop, 3
			{
			y2 := Floor(CaptureH * (A_Index*2 - 1) / 6)
			if (l < 0)
				l := ColorListFirstX(lList, BarColorTolerance, y2, 0, CaptureW - 1)
			if (r < 0)
				r := ColorListLastX(rList, BarColorTolerance, y2, 0, CaptureW - 1)
			if (l >= 0 and r >= 0)
				break
			}
		}
	tcUsed := false
	refW := BarColRef()
	DllCall("QueryPerformanceCounter", "Int64*", tcNow)
	if (MgInPlay and refW > 8 and BarColT and ((tcNow - BarColT) / QpcFreq) <= 3.0)
		{
		curW := (l >= 0 and r > l) ? (r - l + 1) : 0
		if (curW < refW * 0.9 and BarByTrackContrast(row, tcL, tcW) and Abs(tcW - refW) <= refW * 0.25)
			{
			l := tcL
			r := tcL + tcW - 1
			tcUsed := true
			}
		}
	if (!tcUsed and l >= 0 and r > l)
		{
		if (BarEndInside(row, Round(r - FishBarLeft), 1) or BarEndInside(row, Round(l - FishBarLeft), -1))
			{
			if (BarByTrackContrast(row, tcL, tcW) and tcW >= (r - l + 1) * 1.3 and tcW <= CaptureW * 0.75)
				{
				if (tcL <= l + 10 and (tcL + tcW - 1) >= r - 10)
					{
					l := tcL
					r := tcL + tcW - 1
					tcUsed := true
					}
				}
			}
		}

	if (l < 0 or r < 0 or r <= l or (r - l + 1) > CaptureW * 0.75)
		{
		LastBarL := -1
		LastBarR := -1
		BarLiveMiss := BarLiveMiss + 1
		if (BarLiveMiss > 12)
			{
			BarLiveL := -1
			BarLiveR := -1
			BarWLive := -1
			BarLiveOnlyAt := 0
			}
		return false
		}
	LastBarL := l
	LastBarR := r
	if (tcUsed)
		{
		LastBarL := -1
		LastBarR := -1
		}
	RunLeft := l
	RunWidth := r - l + 1
	if (!tcUsed)
		{
		if (!IsObject(BarColRing))
			BarColRing := []
		BarColRing.Push(RunWidth)
		if (BarColRing.MaxIndex() > 5)
			BarColRing.RemoveAt(1)
		BarColT := tcNow
		}
	BarScanRow := row
	BarLiveMiss := 0

	pl := BarPixAt(Round(l - FishBarLeft) + 2, row)
	pr := BarPixAt(Round(r - FishBarLeft) - 2, row)
	cfgOk := false
	if (pl >= 0 and ColorListHitPx(lList, pl, BarColorTolerance))
		cfgOk := true
	if (pr >= 0 and ColorListHitPx(rList, pr, BarColorTolerance))
		cfgOk := true
	if (cfgOk)
		BarLiveOnlyAt := 0
	else
		{
		if (!BarLiveOnlyAt)
			BarLiveOnlyAt := A_TickCount
		else if ((A_TickCount - BarLiveOnlyAt) > 6000)
			{
			BarLiveL := -1
			BarLiveR := -1
			BarWLive := -1
			BarLiveOnlyAt := 0
			LastBarL := -1
			LastBarR := -1
			return false
			}
		}
	if (BarWLive <= 0 or Abs(RunWidth - BarWLive) <= (BarWLive * 0.35))
		{
		if (pl >= 0)
			BarLiveL := BarLiveOk(pl, BarPixAt(Round(l - FishBarLeft) - 10, row), adTol, BarLiveL)
		if (pr >= 0)
			BarLiveR := BarLiveOk(pr, BarPixAt(Round(r - FishBarLeft) + 10, row), adTol, BarLiveR)
		}
	BarWLive := RunWidth
	return true
}

MinigameVisible(minRun) {
	global CaptureW, BarRowAgreement, RunWidth, BarLeftColor, BarRightColor, SpecialRod
	global RunLeft, VgBarL, VgBarW
	if (SpecialRod = "Castbound" or SpecialRod = "Remembrance" or SpecialRod = "MiguRod" or SpecialRod = "Halibut Harpoon"
		or SpecialRod = "Tryhard Rod" or SpecialRod = "Stellarwave Melody")
		return BarPresent()
	if (SpecialRod = "Verdant Oath")
		{
		if (!VerdantBarScan())
			return false
		RunLeft := VgBarL
		RunWidth := VgBarW
		return true
		}
	if (BarLeftColor != "" and BarRightColor != "")
		return FindBarByColor()
	if (!CalibrateBarRow(minRun))
		return false
	if (BarRowAgreement < 3)
		return false
	if (RunWidth > CaptureW * 0.75)
		return false
	return true
}

ColStats(x, ys, ByRef m, ByRef sd) {
	global pCaptureBits, CaptureW
	n := ys.MaxIndex()
	vals := []
	total := 0
	for i, y in ys
		{
		px := NumGet(pCaptureBits + 0, (y*CaptureW*4) + (x*4), "UInt")
		l := ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
		vals[i] := l
		total += l
		}
	m := total / n
	q := 0
	for i, l in vals
		q += (l-m)*(l-m)
	sd := Sqrt(q/n)
}

FindFishBand(xFrom, xTo, barKnown) {
	global CaptureW, CaptureH, FishBarLeft, RunLeft, RunWidth, LastFishX
	ys := []
	Loop, 7
		{
		ry := Floor(CaptureH * (A_Index*2 - 1) / 14)
		if (ry >= CaptureH)
			ry := CaptureH - 1
		ys.Push(ry)
		}
	off := Round(CaptureW * 0.025)
	if (off < 10)
		off := 10
	if (xFrom < off)
		xFrom := off
	if (xTo > CaptureW - off - 1)
		xTo := CaptureW - off - 1
	if (xFrom > xTo)
		return -1

	means := []
	sds := []
	x := xFrom - off
	while (x <= xTo + off)
		{
		ColStats(x, ys, m, sd)
		means[x] := m
		sds[x] := sd
		x++
		}

	bestC := -1
	bestScore := -1
	bandStart := -1
	x := xFrom
	while (x <= xTo + 1)
		{
		ok := false
		if (x <= xTo and sds[x] <= 25)
			{
			dl := means[x] - means[x-off]
			dr := means[x] - means[x+off]
			cmin := (Abs(dl) < Abs(dr)) ? Abs(dl) : Abs(dr)
			if (cmin >= 8 and ((dl > 0) = (dr > 0)))
				ok := true
			}
		if (ok)
			{
			if (bandStart < 0)
				bandStart := x
			}
		else if (bandStart >= 0)
			{
			w := x - bandStart
			if (w >= 5 and w <= 14)
				{
				c := Round(bandStart + w/2)
				dl := means[c] - means[c-off]
				dr := means[c] - means[c+off]
				peak := (Abs(dl) < Abs(dr)) ? Abs(dl) : Abs(dr)
				score := (LastFishX >= 0) ? (100000 - Abs((FishBarLeft + c) - LastFishX)) : peak
				if (score > bestScore)
					{
					bestScore := score
					bestC := c
					}
				}
			bandStart := -1
			}
		x++
		}
	if (bestC < 0)
		return -1
	return FishBarLeft + bestC
}

StripHasFishLine() {
	global CaptureW, CaptureH, BarScanRow
	off := Round(CaptureW * 0.025)
	if (off < 10)
		off := 10
	checkRows := []
	Loop, 5
		{
		ry := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (ry >= CaptureH)
			ry := CaptureH - 1
		checkRows.Push(ry)
		}
	xStart := off
	xEnd := CaptureW - off - 1
	x := xStart
	while (x <= xEnd)
		{
		if (IsDarkNotch(x, BarScanRow, off))
			{
			votes := 0
			for i, ry in checkRows
				{
				if (IsDarkNotch(x, ry, off))
					votes++
				}
			if (votes >= 3)
				return true
			}
		x++
		}
	return false
}

FindColorCenter(targetBGR, tol) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	tB := (targetBGR >> 16) & 0xFF
	tG := (targetBGR >> 8) & 0xFF
	tR := targetBGR & 0xFF
	Loop, 5
		{
		y := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (y < 0)
			y := 0
		if (y >= CaptureH)
			y := CaptureH - 1
		rowOffset := y * CaptureW * 4
		runStart := -1
		runEnd := -1
		x := 0
		while (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			if (Abs(r-tR) <= tol and Abs(g-tG) <= tol and Abs(b-tB) <= tol)
				{
				if (runStart < 0)
					runStart := x
				runEnd := x
				}
			else if (runStart >= 0 and (x - runEnd) > 4)
				break
			x++
			}
		if (runStart >= 0)
			return FishBarLeft + ((runStart + runEnd) / 2)
		}
	return -1
}

GetFishPos() {
	global FishBarColorTolerance, LastFishX, CaptureW, CaptureH, FishBarLeft, FishColor, BarScanRow
	global RelLock, SpecialRod, PinFishX, ControlMode, LineFishX, NoiseFishX, CastFishX, RemTargetX, MiguFishX, HaliFishX
	global TryFishX, SwFishX, SwFishHeld
	if (SpecialRod = "Stellarwave Melody")
		{
		SwScan()
		return SwFishHeld ? -1 : SwFishX
		}
	if (SpecialRod = "Castbound")
		{
		CastboundScan()
		return CastFishX
		}
	if (SpecialRod = "Halibut Harpoon")
		{
		if (HalibutBarScan())
			return HaliFishX
		return -1
		}
	if (SpecialRod = "Noiseform")
		{
		NoiseScan()
		return NoiseFishX
		}
	if (SpecialRod = "Remembrance")
		{
		if (RemembranceScan())
			return RemTargetX
		return -1
		}
	if (SpecialRod = "MiguRod")
		{
		if (MiguScan())
			return MiguFishX
		return -1
		}
	if (SpecialRod = "Tryhard Rod")
		{
		TryhardScan()
		return TryFishX
		}
	if (ControlMode = "Lines")
		{
		LineScan()
		if (LineFishX >= 0)
			{
			if (SpecialRod = "Verdant Oath")
				LastFishX := LineFishX
			return LineFishX
			}
		}
	if (SpecialRod = "Verdant Oath")
		return VerdantFishX()
	if (SpecialRod = "Pinions Aria")
		{
		PinionScan()
		if (PinFishX >= 0)
			return PinFishX
		}
	if (RelLock = 1)
		{
		rfx := FindFishRelative()
		if (rfx >= 0)
			return rfx
		}
	fList := ColorListParse(FishColor)
	tol := FishBarColorTolerance
	row := BarScanRow
	if (row < 0 or row >= CaptureH)
		row := CaptureH // 2

	if (LastFishX >= 0)
		{
		lx := Round(LastFishX - FishBarLeft)
		fx := ColorListCenterX(fList, tol, row, lx - 55, lx + 55)
		if (fx >= 0)
			{
			LastFishX := fx
			return fx
			}
		}
	fx := ColorListCenterX(fList, tol, row, 0, CaptureW - 1)
	if (fx >= 0)
		{
		LastFishX := fx
		return fx
		}
	Loop, 3
		{
		y2 := Floor(CaptureH * (A_Index*2 - 1) / 6)
		fx := ColorListCenterX(fList, tol, y2, 0, CaptureW - 1)
		if (fx >= 0)
			{
			LastFishX := fx
			return fx
			}
		}
	fx := FindFishBand(0, CaptureW - 1, true)
	if (fx >= 0)
		{
		LastFishX := fx
		return fx
		}
	return LastFishX
}

GetFishX() {
	global CaptureW, CaptureH, FishBarLeft, BarScanRow, RunLeft, RunWidth, LastFishX
	y := BarScanRow
	if (y < 0 or y >= CaptureH)
		y := CaptureH // 2
	off := Round(CaptureW * 0.025)
	if (off < 10)
		off := 10
	ref := (LastFishX >= 0) ? LastFishX : (RunLeft + RunWidth/2)

	checkRows := []
	Loop, 5
		{
		ry := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (ry < 0)
			ry := 0
		if (ry >= CaptureH)
			ry := CaptureH - 1
		checkRows.Push(ry)
		}

	bestX := -1
	bestDist := 999999
	x := off
	while (x < CaptureW - off)
		{
		if (IsDarkNotch(x, y, off))
			{
			votes := 0
			for i, ry in checkRows
				{
				if (IsDarkNotch(x, ry, off))
					votes++
				}
			if (votes >= 3)
				{
				cx := FishBarLeft + x
				d := Abs(cx - ref)
				if (d < bestDist)
					{
					bestDist := d
					bestX := cx
					}
				}
			}
		x++
		}
	if (bestX < 0)
		return -1
	LastFishX := bestX
	return bestX
}

IsDarkNotch(x, y, off) {
	global pCaptureBits, CaptureW, CaptureH
	if (y < 0 or y >= CaptureH or x < off or x >= CaptureW - off)
		return false
	rowOffset := y * CaptureW * 4
	pc := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
	pl := NumGet(pCaptureBits + 0, rowOffset + ((x-off)*4), "UInt")
	pr := NumGet(pCaptureBits + 0, rowOffset + ((x+off)*4), "UInt")
	c := ((pc & 0xFF) + ((pc >> 8) & 0xFF) + ((pc >> 16) & 0xFF)) // 3
	lN := ((pl & 0xFF) + ((pl >> 8) & 0xFF) + ((pl >> 16) & 0xFF)) // 3
	rN := ((pr & 0xFF) + ((pr >> 8) & 0xFF) + ((pr >> 16) & 0xFF)) // 3
	navg := (lN + rN) // 2
	margin := Round(navg * 0.25)
	if (margin < 8)
		margin := 8
	return (lN - c >= margin and rN - c >= margin)
}

FindColorX(targetHex, tol) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	tB := (targetHex >> 16) & 0xFF
	tG := (targetHex >> 8) & 0xFF
	tR := targetHex & 0xFF
	Loop, 5
		{
		y := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (y < 0)
			y := 0
		if (y >= CaptureH)
			y := CaptureH - 1
		rowOffset := y * CaptureW * 4
		Loop, % CaptureW
			{
			x := A_Index - 1
			px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			if (Abs(r-tR) <= tol and Abs(g-tG) <= tol and Abs(b-tB) <= tol)
				return FishBarLeft + x
			}
		}
	return -1
}


BGR(hex) {
	r := "0x" . SubStr(hex,1,2)
	g := "0x" . SubStr(hex,3,2)
	b := "0x" . SubStr(hex,5,2)
	return (b<<16) | (g<<8) | r
}

EnsureBrush(ByRef hBrush, hexColor) {
	if (!hBrush)
		hBrush := DllCall("CreateSolidBrush", "UInt", BGR(hexColor), "Ptr")
	return hBrush
}

WM_CTLCOLOREDIT(wParam, lParam, msg, hwnd) {
	global hBrushInput, ColorInputBGR, ColorInput, hMgCodeBox, hBrushWhite
	DllCall("SetBkMode", "Ptr", wParam, "Int", 1)
	DllCall("SetTextColor", "Ptr", wParam, "UInt", 0xFFFFFF)
	DllCall("SetBkColor", "Ptr", wParam, "UInt", ColorInputBGR)
	return EnsureBrush(hBrushInput, ColorInput)
}

WM_CTLCOLORBTN(wParam, lParam, msg, hwnd) {
	global hBrushBG, ColorTextBGR, ColorBG
	DllCall("SetBkMode", "Ptr", wParam, "Int", 1)
	DllCall("SetTextColor", "Ptr", wParam, "UInt", ColorTextBGR)
	return EnsureBrush(hBrushBG, ColorBG)
}

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
	global IconTips
	static lastHwnd := 0
	if (hwnd = lastHwnd)
		return
	lastHwnd := hwnd
	if (IsObject(IconTips) and IconTips.HasKey(hwnd))
		{
		ToolTip, % IconTips[hwnd], , , 3
		SetTimer, ClearIconTip, 120
		}
	else
		ToolTip, , , , 3
}

WM_SETCURSOR(wParam, lParam, msg, hwnd) {
	global hVersionsBtn
	if (hVersionsBtn and wParam = hVersionsBtn)
		{
		DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
		return true
		}
}

WM_MOUSEWHEEL(wParam, lParam, msg, hwnd) {
	global hFaqBox, GuiHwnd, SIDEW, HEADH, BARH, DpiF
	mwD := (wParam >> 16) & 0xFFFF
	if (mwD > 32767)
		mwD -= 65536
	MouseGetPos, , , , mwCtl, 2
	if (hFaqBox and mwCtl = hFaqBox)
		{
		mwLines := (mwD > 0) ? -3 : 3
		SendMessage, 0xB6, 0, %mwLines%, , ahk_id %hFaqBox%
		return 0
		}
	if (!GuiHwnd)
		return
	mwSx := lParam & 0xFFFF
	if (mwSx > 32767)
		mwSx -= 65536
	mwSy := (lParam >> 16) & 0xFFFF
	if (mwSy > 32767)
		mwSy -= 65536
	VarSetCapacity(mwPt, 8, 0)
	NumPut(mwSx, mwPt, 0, "Int")
	NumPut(mwSy, mwPt, 4, "Int")
	DllCall("ScreenToClient", "Ptr", GuiHwnd, "Ptr", &mwPt)
	mwCx := NumGet(mwPt, 0, "Int") / DpiF
	mwCy := NumGet(mwPt, 4, "Int") / DpiF
	if (mwCx < SIDEW or mwCy < HEADH + BARH)
		return
	ScrollBy((mwD > 0) ? -66 : 66)
	return 0
}

WM_CTLCOLORSTATIC(wParam, lParam, msg, hwnd) {
	global hBrushBG, hBrushGreen, hBrushRed, hStartStopBtnHwnd, SpecialBrushes, MacroRunning, ColorTextBGR
	global ColorBG, ColorGreen, ColorRed, hFrzGui
	if (hFrzGui and DllCall("GetParent", "Ptr", lParam, "Ptr") = hFrzGui)
		return
	DllCall("SetBkMode", "Ptr", wParam, "Int", 1)
	if (lParam = hStartStopBtnHwnd)
		{
		DllCall("SetTextColor", "Ptr", wParam, "UInt", 0xFFFFFF)
		if (MacroRunning)
			return EnsureBrush(hBrushRed, ColorRed)
		return EnsureBrush(hBrushGreen, ColorGreen)
		}
	if (IsObject(SpecialBrushes) and SpecialBrushes.HasKey(lParam))
		{
		e := SpecialBrushes[lParam]
		if (e.brush)
			{
			DllCall("SetTextColor", "Ptr", wParam, "UInt", e.text)
			return e.brush
			}
		}
	DllCall("SetTextColor", "Ptr", wParam, "UInt", ColorTextBGR)
	return EnsureBrush(hBrushBG, ColorBG)
}

;====================================================================================================;

;====================================================================================================;
;====================================================================================================;

CtrlSnapPos(h, ByRef cx, ByRef cy, ByRef cw, ByRef ch) {
	global GuiHwnd, DpiF
	VarSetCapacity(sr, 16, 0)
	DllCall("GetWindowRect", "Ptr", h, "Ptr", &sr)
	VarSetCapacity(sp, 8, 0)
	NumPut(NumGet(sr, 0, "Int"), sp, 0, "Int")
	NumPut(NumGet(sr, 4, "Int"), sp, 4, "Int")
	DllCall("ScreenToClient", "Ptr", GuiHwnd, "Ptr", &sp)
	cx := Round(NumGet(sp, 0, "Int") / DpiF)
	cy := Round(NumGet(sp, 4, "Int") / DpiF)
	cw := Round((NumGet(sr, 8, "Int") - NumGet(sr, 0, "Int")) / DpiF)
	ch := Round((NumGet(sr, 12, "Int") - NumGet(sr, 4, "Int")) / DpiF)
}

SnapshotBase(lst) {
	global CtrlBaseX, CtrlBaseY, CtrlW, CtrlH
	for i, h in lst
		{
		if (CtrlBaseY.HasKey(h))
			continue
		CtrlSnapPos(h, cx, cy, cw, ch)
		CtrlBaseX[h] := cx
		CtrlBaseY[h] := cy
		CtrlW[h] := cw
		CtrlH[h] := ch
		}
}

; pages are built in design coordinates; move each new control into the slim shell once
; (General's own controls also drop below the Profile card)
ShiftCtrls(lst, keepFirst := 0) {
	global XS, YS, PROFDY, DpiF, ShiftedSet
	if (!IsObject(ShiftedSet))
		ShiftedSet := {}
	for i, h in lst
		{
		if (ShiftedSet.HasKey(h))
			continue
		ShiftedSet[h] := 1
		CtrlSnapPos(h, cx, cy, cw, ch)
		dy := (keepFirst and i > keepFirst) ? PROFDY : 0
		DllCall("SetWindowPos", "Ptr", h, "Ptr", 0, "Int", Round((cx - XS) * DpiF), "Int", Round((cy - YS + dy) * DpiF)
			, "Int", 0, "Int", 0, "UInt", 0x15)
		}
}

ShellDragDown(wParam, lParam, msg, hwnd) {
	global GuiHwnd, TOPH, SIDEW, DpiF
	if (hwnd != GuiHwnd)
		return
	y := (lParam >> 16) & 0xFFFF
	x := lParam & 0xFFFF
	if (y < TOPH * DpiF or x < SIDEW * DpiF)
		{
		PostMessage, 0xA1, 2, 0, , ahk_id %GuiHwnd%
		return 0
		}
}

SetBase(h, x, y) {
	global CtrlBaseX, CtrlBaseY, CtrlW, CtrlH, XS, YS
	CtrlBaseX[h] := x - XS
	CtrlBaseY[h] := y - YS
	if (!CtrlH.HasKey(h) or !CtrlW.HasKey(h))
		{
		CtrlSnapPos(h, cx, cy, cw, ch)
		CtrlW[h] := cw
		CtrlH[h] := ch
		}
}

ShowList(lst, cond) {
	global HelpHidden
	hh := IsObject(HelpHidden)
	for i, h in lst
		GuiControl, % ((cond and !(hh and HelpHidden.HasKey(h))) ? "1:Show" : "1:Hide"), %h%
}

CollectVisible() {
	global AllManaged, VisibleCtrls
	VisibleCtrls := []
	for i, h in AllManaged
		{
		if (DllCall("GetWindowLong", "Ptr", h, "Int", -16) & 0x10000000)
			VisibleCtrls.Push(h)
		}
}

ApplyScroll() {
	global VisibleCtrls, CtrlBaseX, CtrlBaseY, CtrlW, CtrlH, CtrlRgnR, CtrlClip
	global SecScroll, SecMaxScroll, TargetSection, WINH, WINW, SecTopEdge, GuiHwnd
	global SbTrack, SbThumb, SbTrackH, SbThumbH, SbShown, DpiF
	bot := 0
	for i, h in VisibleCtrls
		{
		if (!CtrlBaseY.HasKey(h))
			continue
		bb := CtrlBaseY[h] + CtrlH[h]
		if (bb > bot)
			bot := bb
		}
	mx := bot + 14 - WINH
	if (mx < 0)
		mx := 0
	SecMaxScroll := mx
	off := SecScroll.HasKey(TargetSection) ? SecScroll[TargetSection] : 0
	if (off > mx)
		off := mx
	if (off < 0)
		off := 0
	SecScroll[TargetSection] := off

	if (SbTrack and SbThumb)
		{
		SbTop := SecTopEdge + 6
		SbH := WINH - SbTop - 12
		SbX := WINW - 15
		if (mx <= 0 or SbH < 40)
			{
			if (SbShown != 0)
				{
				SbShown := 0
				GuiControl, 1:Hide, %SbTrack%
				GuiControl, 1:Hide, %SbThumb%
				}
			}
		else
			{
			SbView := WINH - SecTopEdge
			SbTh := Round(SbH * SbView / (SbView + mx))
			if (SbTh < 30)
				SbTh := 30
			if (SbTh > SbH)
				SbTh := SbH
			SbY := SbTop + Round((SbH - SbTh) * off / mx)
			GuiControl, 1:Move, %SbTrack%, % "x" . SbX . " y" . SbTop . " w9 h" . SbH
			GuiControl, 1:Move, %SbThumb%, % "x" . SbX . " y" . SbY . " w9 h" . SbTh
			if (SbTrackH != SbH)
				{
				SbTrackH := SbH
				SbRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", Round(9 * DpiF) + 1, "Int", Round(SbH * DpiF) + 1
					, "Int", Round(9 * DpiF), "Int", Round(9 * DpiF), "Ptr")
				DllCall("SetWindowRgn", "Ptr", SbTrack, "Ptr", SbRgn, "Int", true)
				}
			if (SbThumbH != SbTh)
				{
				SbThumbH := SbTh
				SbRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", Round(9 * DpiF) + 1, "Int", Round(SbTh * DpiF) + 1
					, "Int", Round(9 * DpiF), "Int", Round(9 * DpiF), "Ptr")
				DllCall("SetWindowRgn", "Ptr", SbThumb, "Ptr", SbRgn, "Int", true)
				}
			if (SbShown != 1)
				{
				SbShown := 1
				GuiControl, 1:Show, %SbTrack%
				GuiControl, 1:Show, %SbThumb%
				}
			}
		}

	n := VisibleCtrls.MaxIndex()
	if (!n)
		return
	shrunk := []
	hdwp := DllCall("BeginDeferWindowPos", "Int", n, "Ptr")
	for i, h in VisibleCtrls
		{
		if (!CtrlBaseY.HasKey(h))
			continue
		ny := CtrlBaseY[h] - off
		if (!IsCard(h))
			{
			if (ny < SecTopEdge)
				ny := -6000
			hdwp := DllCall("DeferWindowPos", "Ptr", hdwp, "Ptr", h, "Ptr", 0
				, "Int", Round(CtrlBaseX[h] * DpiF), "Int", (ny = -6000) ? ny : Round(ny * DpiF), "Int", 0, "Int", 0, "UInt", 0x001D, "Ptr")
			continue
			}
		cw := CtrlW[h]
		ch := CtrlH[h]
		nh := ch
		cut := 0
		if (ny + ch <= SecTopEdge)
			ny := -6000
		else if (ny < SecTopEdge)
			{
			cut := SecTopEdge - ny
			nh := ch - cut
			ny := SecTopEdge
			}
		shrunk.Push({h: h, cut: cut, w: cw, r: CtrlRgnR[h], ht: nh})
		hdwp := DllCall("DeferWindowPos", "Ptr", hdwp, "Ptr", h, "Ptr", 0
			, "Int", Round(CtrlBaseX[h] * DpiF), "Int", (ny = -6000) ? ny : Round(ny * DpiF)
			, "Int", Round(cw * DpiF), "Int", Round(nh * DpiF), "UInt", 0x0014, "Ptr")
		}
	DllCall("EndDeferWindowPos", "Ptr", hdwp)

	for i, e in shrunk
		{
		h := e.h
		prev := CtrlClip.HasKey(h) ? CtrlClip[h] : 0
		if (e.cut = prev)
			continue
		CtrlClip[h] := e.cut
		if (e.cut > 0)
			DllCall("SetWindowRgn", "Ptr", h, "Ptr", 0, "Int", true)
		else
			{
			rgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", Round(e.w * DpiF) + 1, "Int", Round(e.ht * DpiF) + 1
				, "Int", Round(e.r * 2 * DpiF), "Int", Round(e.r * 2 * DpiF), "Ptr")
			DllCall("SetWindowRgn", "Ptr", h, "Ptr", rgn, "Int", true)
			}
		}
	DllCall("RedrawWindow", "Ptr", GuiHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
}

IsCard(h) {
	global CtrlRgnR, CtrlH
	if (!CtrlRgnR.HasKey(h) or !CtrlH.HasKey(h))
		return false
	return (CtrlRgnR[h] > 0 and CtrlH[h] > 44)
}


ScrollBy(delta) {
	global SecScroll, SecMaxScroll, TargetSection, GuiHwnd
	off := SecScroll.HasKey(TargetSection) ? SecScroll[TargetSection] : 0
	nw := off + delta
	if (nw < 0)
		nw := 0
	if (nw > SecMaxScroll)
		nw := SecMaxScroll
	if (nw = off)
		return
	SecScroll[TargetSection] := nw
	if (GuiHwnd)
		{
		DllCall("SendMessage", "Ptr", GuiHwnd, "UInt", 0x000B, "Ptr", 0, "Ptr", 0)
		ApplyScroll()
		DllCall("SendMessage", "Ptr", GuiHwnd, "UInt", 0x000B, "Ptr", 1, "Ptr", 0)
		DllCall("RedrawWindow", "Ptr", GuiHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
		}
	else
		ApplyScroll()
}

;====================================================================================================;
;====================================================================================================;

MgCodeCue(txt) {
	global hMgCodeBox
	if (hMgCodeBox)
		DllCall("SendMessage", "Ptr", hMgCodeBox, "UInt", 0x1501, "Ptr", 1, "WStr", txt)
}

MgBlockOpen(name, cardY, h) {
	global MgBlocks, MgAllCtrls, CARDX, CARDW
	hc := AddPanel(CARDX, cardY, CARDW, h)
	MgBlocks[name] := {card: hc, y: cardY, h: h, ctrls: [], dxs: [], dys: []}
	MgAllCtrls.Push(hc)
}

MgAdd(name, h) {
	global MgBlocks, MgAllCtrls, CtrlW, CtrlH
	b := MgBlocks[name]
	if (!IsObject(b))
		return
	CtrlSnapPos(h, cx, cy, cw, ch)
	b.ctrls.Push(h)
	b.dxs.Push(cx)
	b.dys.Push(cy - b.y)
	if (!CtrlW.HasKey(h))
		CtrlW[h] := cw
	if (!CtrlH.HasKey(h))
		CtrlH[h] := ch
	MgAllCtrls.Push(h)
}

LayoutMinigame() {
	global MgBlocks, MgVisible, SpecialRod, ControlMode, CARDX, MiniTop
	MgVisible := {}
	vis := ["mode"]
	if (SpecialRod = "Halibut Harpoon")
		vis.Push("halicol")
	if (SpecialRod = "Remembrance")
		vis.Push("remem")
	if (SpecialRod = "Pinions Aria")
		vis.Push("notes")
	else if ((ControlMode != "Lines" or SpecialRod = "Remembrance") and SpecialRod != "Tryhard Rod" and SpecialRod != "Stellarwave Melody")
		vis.Push("colors")
	if (SpecialRod = "Stellarwave Melody")
		{
		vis.Push("stellar")
		vis.Push("swcol")
		}
	if (SpecialRod = "Tryhard Rod")
		vis.Push("trycol")
	if (SpecialRod = "Castbound")
		vis.Push("cbcol")
	if (SpecialRod = "Requiem")
		vis.Push("reel")
	if (ControlMode = "Manual")
		vis.Push("manual")
	else
		vis.Push("precision")
	vis.Push("barctl")
	if (ControlMode = "Manual")
		vis.Push("manrules")
	else
		vis.Push("precrules")
	vis.Push("detcheck")
	y := MiniTop
	for i, nm in vis
		{
		b := MgBlocks[nm]
		if (!IsObject(b))
			continue
		MgVisible[nm] := 1
		SetBase(b.card, CARDX, y)
		for j, h in b.ctrls
			SetBase(h, b.dxs[j], y + b.dys[j])
		y += b.h + 10
		}
}

AddPanel(px, py, pw, ph, pr := 10) {
	global SpecialBrushes, hBrushCard, ColorTextBGR, CardRects, CtrlRgnR, CtrlW, CtrlH
	if (!IsObject(CardRects))
		CardRects := []
	CardRects.Push({x: px, y: py, w: pw, h: ph})
	Gui, 1:Add, Text, x%px% y%py% w%pw% h%ph% HwndhPnl
	SpecialBrushes[hPnl] := {brush: hBrushCard, text: ColorTextBGR}
	if (pr > 0)
		RoundCtrl(hPnl, pw, ph, pr)
	return hPnl
}

FixCardBrushes(lst) {
	global SpecialBrushes, hBrushCard, ColorTextBGR, CardRects, GuiHwnd, DpiF
	if (!IsObject(CardRects))
		return
	for i, h in lst
		{
		if (SpecialBrushes.HasKey(h))
			continue
		VarSetCapacity(fcr, 16, 0)
		DllCall("GetWindowRect", "Ptr", h, "Ptr", &fcr)
		VarSetCapacity(fcp, 8, 0)
		NumPut(NumGet(fcr, 0, "Int"), fcp, 0, "Int")
		NumPut(NumGet(fcr, 4, "Int"), fcp, 4, "Int")
		DllCall("ScreenToClient", "Ptr", GuiHwnd, "Ptr", &fcp)
		cx := Round(NumGet(fcp, 0, "Int") / DpiF)
		cy := Round(NumGet(fcp, 4, "Int") / DpiF)
		for j, rc in CardRects
			{
			if (cx >= rc.x and cy >= rc.y and cx < rc.x + rc.w and cy < rc.y + rc.h)
				{
				SpecialBrushes[h] := {brush: hBrushCard, text: ColorTextBGR}
				break
				}
			}
		}
}

ThemeCtl(h) {
	global GuiInputs
	VarSetCapacity(cb, 128, 0)
	DllCall("GetClassName", "Ptr", h, "Str", cb, "Int", 64)
	cls := cb
	DllCall("uxtheme\SetWindowTheme", "Ptr", h, "Str", (cls = "ComboBox") ? "DarkMode_CFD" : "DarkMode_Explorer", "Ptr", 0)
	if (GuiInputs != "Filled")
		return
	if (cls = "Edit")
		{
		st := DllCall("GetWindowLong", "Ptr", h, "Int", -16, "Int")
		DllCall("SetWindowLong", "Ptr", h, "Int", -16, "Int", st & ~0x800000)
		ex := DllCall("GetWindowLong", "Ptr", h, "Int", -20, "Int")
		DllCall("SetWindowLong", "Ptr", h, "Int", -20, "Int", ex & ~0x200)
		DllCall("SetWindowPos", "Ptr", h, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x27)
		DllCall("SendMessage", "Ptr", h, "UInt", 0xD3, "Ptr", 3, "Ptr", (7 << 16) | 7)
		}
	if (cls = "Edit" or cls = "ComboBox")
		{
		CtrlSnapPos(h, cx, cy, cw, ch)
		if (cw > 4 and ch > 4)
			RoundCtrl(h, cw, ch, (ch > 40) ? 9 : 7)
		}
}

; round every box-like control that was not rounded when it was made
RoundExtras() {
	global GuiHwnd, CtrlRgnR, GuiInputs
	if (!GuiHwnd)
		return
	dhw := A_DetectHiddenWindows
	DetectHiddenWindows, On
	WinGet, lst, ControlListHwnd, ahk_id %GuiHwnd%
	DetectHiddenWindows, %dhw%
	Loop, Parse, lst, `n
		{
		h := A_LoopField + 0
		if (CtrlRgnR.HasKey(h))
			continue
		VarSetCapacity(cb, 128, 0)
		DllCall("GetClassName", "Ptr", h, "Str", cb, "Int", 64)
		cls := cb
		if (cls = "msctls_progress32" or cls = "ComboBox" or (cls = "Edit" and GuiInputs = "Filled"))
			{
			CtrlSnapPos(h, cx, cy, cw, ch)
			if (cw > 4 and ch > 4)
				RoundCtrl(h, cw, ch, (cls = "msctls_progress32") ? 5 : ((ch > 40) ? 9 : 7))
			}
		}
}

; minimal look: the ? help icons go away (their tips go with them)
HideHelpIcons() {
	global GuiHwnd, GuiHelp, HelpHidden
	if (GuiHelp != "Hide" or !GuiHwnd)
		return
	if (!IsObject(HelpHidden))
		HelpHidden := {}
	dhw := A_DetectHiddenWindows
	DetectHiddenWindows, On
	WinGet, lst, ControlListHwnd, ahk_id %GuiHwnd%
	DetectHiddenWindows, %dhw%
	Loop, Parse, lst, `n
		{
		h := A_LoopField + 0
		if (HelpHidden.HasKey(h))
			continue
		VarSetCapacity(tb, 16, 0)
		DllCall("GetWindowText", "Ptr", h, "Str", tb, "Int", 8)
		if (tb = "?")
			{
			HelpHidden[h] := 1
			DllCall("ShowWindow", "Ptr", h, "Int", 0)
			}
		}
}

ColorShift(hex, amt) {
	r := Format("{:d}", "0x" . SubStr(hex, 1, 2)) + amt
	g := Format("{:d}", "0x" . SubStr(hex, 3, 2)) + amt
	b := Format("{:d}", "0x" . SubStr(hex, 5, 2)) + amt
	r := (r > 255) ? 255 : ((r < 0) ? 0 : r)
	g := (g > 255) ? 255 : ((g < 0) ? 0 : g)
	b := (b > 255) ? 255 : ((b < 0) ? 0 : b)
	return Format("{:02X}{:02X}{:02X}", r, g, b)
}

RoundCtrl(h, w, ht, r) {
	global CtrlRgnR, CtrlW, CtrlH, DpiF, GuiRoundMul
	mul := (GuiRoundMul = "") ? 1 : GuiRoundMul
	r := r * mul
	if (r < 0.5)
		r := 0.5
	CtrlRgnR[h] := r
	CtrlW[h] := w
	CtrlH[h] := ht
	rgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", Round(w * DpiF) + 1, "Int", Round(ht * DpiF) + 1
		, "Int", Round(r * 2 * DpiF), "Int", Round(r * 2 * DpiF), "Ptr")
	DllCall("SetWindowRgn", "Ptr", h, "Ptr", rgn, "Int", true)
}

;====================================================================================================;

BuildGui:

IniRead, GuiTheme, %SettingsFile%, GUI, Theme, Mono
IniRead, GuiCorners, %SettingsFile%, GUI, Corners, Square
IniRead, GuiInputs, %SettingsFile%, GUI, Inputs, Filled
IniRead, GuiHelp, %SettingsFile%, GUI, HelpIcons, Show
GuiRoundMul := {"Square": 0, "Subtle": 0.55, "Rounded": 1, "Extra round": 1.7}[GuiCorners]
if (GuiRoundMul = "")
	{
	GuiCorners := "Square"
	GuiRoundMul := 0
	}
GuiThemes := {"Mono": ["0B0B0D", "101012", "17171A", "0D0D0F", "E6E6E8", "EDEDEF", "85858C", "26262B", "8E8E95"]
	, "Midnight": ["0D1117", "121722", "171D2A", "0A0E15", "6E9BFF", "E3E8F2", "8590A6", "242C3D", "AEB8CC"]
	, "Violet":  ["0F0D16", "15121F", "1C1829", "0B0A11", "A78BFA", "ECE8FA", "958CB0", "2B2540", "BDB4D6"]
	, "Emerald": ["0B1210", "101915", "15211B", "08100D", "34D399", "E2F2EA", "86A597", "22322B", "AFC9BC"]
	, "Crimson": ["130C0E", "1A1114", "22161A", "0E090A", "FB7185", "F4E6E9", "AA8B92", "3A242A", "D0B3B9"]
	, "Classic": ["121212", "1E1E1E", "1B1B1B", "0E0E0E", "5EA6FF", "4EA1F7", "3B6E99", "2A2A2A", "4EA1F7"] }
if (!GuiThemes.HasKey(GuiTheme))
	GuiTheme := "Mono"
GtP := GuiThemes[GuiTheme]
ColorBG := GtP[1]
ColorPanel := GtP[2]
ColorCard := GtP[3]
ColorInput := GtP[4]
ColorAccent := GtP[5]
ColorText := GtP[6]
ColorMuted := GtP[7]
ColorBorder := GtP[8]
ColorNav := GtP[9]
if (GuiInputs = "Filled")
	ColorInput := ColorShift(ColorCard, 14)
ColorGreen := "22C55E"
ColorRed := "EF4444"
ColorAmber := "F59E0B"
ColorDark := "1F2937"

ColorWhite := "FFFFFF"
ColorTextBGR := BGR(ColorText)
ColorWhiteBGR := BGR(ColorWhite)
ColorPanelBGR := BGR(ColorPanel)
ColorCardBGR := BGR(ColorCard)
ColorInputBGR := BGR(ColorInput)
ColorDarkBGR := BGR(ColorDark)
ColorMutedBGR := BGR(ColorMuted)
ColorAccentBGR := BGR(ColorAccent)
ColorGreenBGR := BGR(ColorGreen)
ColorAmberBGR := BGR(ColorAmber)
ColorYellowBGR := BGR("FACC15")
ColorRedBGR := BGR(ColorRed)
ColorNavBGR := BGR(ColorNav)

hBrushBG := DllCall("CreateSolidBrush", "UInt", BGR(ColorBG), "Ptr")
hBrushPanel := DllCall("CreateSolidBrush", "UInt", BGR(ColorPanel), "Ptr")
hBrushCard := DllCall("CreateSolidBrush", "UInt", BGR(ColorCard), "Ptr")
hBrushInput := DllCall("CreateSolidBrush", "UInt", BGR(ColorInput), "Ptr")
hBrushGreen := DllCall("CreateSolidBrush", "UInt", BGR(ColorGreen), "Ptr")
hBrushRed := DllCall("CreateSolidBrush", "UInt", BGR(ColorRed), "Ptr")
hBrushBorder := DllCall("CreateSolidBrush", "UInt", BGR(ColorBorder), "Ptr")
hBrushSbTrack := DllCall("CreateSolidBrush", "UInt", BGR("1A1A1A"), "Ptr")
hBrushSbThumb := DllCall("CreateSolidBrush", "UInt", BGR("6E6E6E"), "Ptr")
hBrushAmber := DllCall("CreateSolidBrush", "UInt", BGR(ColorAmber), "Ptr")
hBrushAccent := DllCall("CreateSolidBrush", "UInt", BGR(ColorAccent), "Ptr")

SpecialBrushes := {}

OnMessage(0x133, "WM_CTLCOLOREDIT")
OnMessage(0x135, "WM_CTLCOLORBTN")
OnMessage(0x138, "WM_CTLCOLORSTATIC")

GeneralCtrls := []
HomeCtrls := []
CastCtrls := []
NormalCastCtrls := []
PerfectCastCtrls := []
ShakeCtrls := []
UtilCtrls := []
TotemCtrls := []
MiscCtrls := []
TotemBodyCtrls := []
AquariumCtrls := []
AquariumBodyCtrls := []
KeeperCtrls := []
KeeperBodyCtrls := []
AdvCtrls := []
GuessCtrls := []
GuessBodyCtrls := []
WebhookCtrls := []
WebhookBodyCtrls := []
FaqCtrls := []
AboutCtrls := []
VersionsCtrls := []
ReadThisCtrls := []
ThemedCtrls := []
CMCtrls := []
NavHwnd := {}

; Swift-style shell: slim icon sidebar + slim top strip. Pages are still laid out in their original
; ("design") coordinates and shifted left/up by XS/YS when built, so nothing inside them had to change.
XS := 108
YS := 62
PROFDY := 104
WINW := 652
WINH := 620
SIDEW := 64
TOPH := 48
HEADH := 48
BARH := 0
CARDX := 188
CARDW := 556
CX := 204
LW := 230
IX := 442
IW := 200
SWX := 678
SWW := 44
QX := 652
DX := 586
DW := 56
RH := 26
TXW := 524
ContentTop := 136

Gui, +HwndGuiHwnd -MaximizeBox -Caption +MinimizeBox +0x02000000
Gui, Font, s9 c%ColorText%, Segoe UI
Gui, Color, %ColorBG%, %ColorBG%
Gui, Margin, 0, 0

;---- Top strip (drag the window by it) -------------------------------------------------------------

IconTips := {}

Gui, Font, s11 Bold c%ColorText%, Segoe UI
TitleX := SIDEW + 16
Gui, Add, Text, x%TitleX% y9 w220 h20 HwndhTitleText, DeepFish
SpecialBrushes[hTitleText] := {brush: hBrushBG, text: ColorTextBGR}
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%TitleX% y28 w260 h14 HwndhSubtitle, ULTIMATE  ·  v%DFVersion%  ·  Made by Yato
SpecialBrushes[hSubtitle] := {brush: hBrushBG, text: ColorMutedBGR}

CloseX := WINW - 44
MinX := CloseX - 40
Gui, Font, s11 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%MinX% y8 w36 h30 Center +0x100 +0x200 gShellMin HwndhShellMin, ─
SpecialBrushes[hShellMin] := {brush: hBrushBG, text: ColorMutedBGR}
RoundCtrl(hShellMin, 36, 30, 8)
IconTips[hShellMin] := "Minimize"
Gui, Add, Text, x%CloseX% y8 w36 h30 Center +0x100 +0x200 gShellClose HwndhShellClose, ✕
SpecialBrushes[hShellClose] := {brush: hBrushBG, text: ColorMutedBGR}
RoundCtrl(hShellClose, 36, 30, 8)

StartX := MinX - 92
StartStopLabel := MacroRunning ? "⏹ Stop" : "▶ Start"
Gui, Font, s9 Bold cFFFFFF, Segoe UI
Gui, Add, Text, x%StartX% y9 w84 h30 Center +0x100 +0x200 vStartStopDisplay gPreviewOrToggle HwndhStartStopBtnHwnd, %StartStopLabel%
StatusX := StartX - 98
Gui, Font, s9 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%StatusX% y11 w90 h26 Center +0x100 +0x200 vRunStatusText HwndhRunStatus, ●  Idle
SpecialBrushes[hRunStatus] := {brush: hBrushPanel, text: ColorMutedBGR}
RoundCtrl(hRunStatus, 90, 26, 13)


;---- Profile tools: they live in a card at the top of General -----------------------------------------
; (made here in General's design coordinates, then handed to General so they move with it)

ProfCardH := 94
hC := AddPanel(CARDX, 120, CARDW, ProfCardH)
GeneralCtrls.Push(hC)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y130 w200 h16 HwndhProfIcon, PROFILE
SpecialBrushes[hProfIcon] := {brush: hBrushCard, text: ColorMutedBGR}
GeneralCtrls.Push(hProfIcon)
Gui, Font, s9 c%ColorText%, Segoe UI
Gui, Add, DropDownList, x%CX% y150 w170 h240 vProfileSelect gProfileSelect HwndhProfileSelect
ThemedCtrls.Push(hProfileSelect)
GeneralCtrls.Push(hProfileSelect)
gosub, RefreshProfileList

PfX := CX + 178
for i, d in [["ProfileNew", "hTipNew", "➕", "New profile"], ["ProfileDuplicate", "hTipDup", "📄", "Duplicate current profile"]
	, ["ProfileDelete", "hTipDel", "🗑", "Delete current profile"], ["RevertSettings", "hTipRevert", "↶", "Undo the last save (restores the previous saved values)"]]
	{
	pg := d[1]
	Gui, Add, Text, x%PfX% y149 w30 h26 Center +0x100 +0x200 g%pg% HwndhPf, % d[3]
	PfVar := d[2]
	%PfVar% := hPf
	SpecialBrushes[hPf] := {brush: hBrushBorder, text: ColorTextBGR}
	RoundCtrl(hPf, 30, 26, 7)
	IconTips[hPf] := d[4]
	GeneralCtrls.Push(hPf)
	PfX += 34
	}

Gui, Font, s9 Norm c%ColorText%, Segoe UI
autoChk := GuiAutoSave ? "Checked" : ""
AsX := CARDX + CARDW - 16 - 84 - 96
Gui, Add, CheckBox, x%AsX% y152 w90 h20 c%ColorText% vGuiAutoSave %autoChk% gToggleAutoSave HwndhTipAuto, Auto-save
SpecialBrushes[hTipAuto] := {brush: hBrushCard, text: ColorTextBGR}
IconTips[hTipAuto] := "Save automatically whenever a setting changes"
GeneralCtrls.Push(hTipAuto)
SvX := CARDX + CARDW - 16 - 84
Gui, Font, s9 Bold, Segoe UI
Gui, Add, Text, x%SvX% y148 w84 h28 Center +0x100 +0x200 vSaveStatusText gSaveSettings HwndhTipSave, 💾 Save
SpecialBrushes[hTipSave] := {brush: hBrushAccent, text: 0x101010}
RoundCtrl(hTipSave, 84, 28, 8)
IconTips[hTipSave] := "Save settings to current profile"
GeneralCtrls.Push(hTipSave)

Gui, Font, s9 c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y181 w30 h26 Center +0x100 +0x200 gMgCopyCode HwndhTipCopy, 📋
SpecialBrushes[hTipCopy] := {brush: hBrushBorder, text: ColorTextBGR}
RoundCtrl(hTipCopy, 30, 26, 7)
IconTips[hTipCopy] := "Copy your Minigame settings as a code"
GeneralCtrls.Push(hTipCopy)
CbX := CX + 38
Gui, Font, s9 Norm cFFFFFF, Segoe UI
Gui, Add, Edit, x%CbX% y182 w260 h24 -Multi vMgCodeBox gMgCodeBoxChanged HwndhMgCodeBox
ThemedCtrls.Push(hMgCodeBox)
GeneralCtrls.Push(hMgCodeBox)
MgCodeBoxPrevLen := 0
MgCodeCue("Paste a minigame code here")
IconTips[hMgCodeBox] := "Paste a Minigame settings code someone sent you.`nIt is applied and saved as soon as you paste it."
GenProfN := GeneralCtrls.Length()

Gui, Font, s9 c%ColorAccent%, Segoe UI

OnMessage(0x200, "WM_MOUSEMOVE")
OnMessage(0x20A, "WM_MOUSEWHEEL")
OnMessage(0x20, "WM_SETCURSOR")
OnMessage(0x201, "ShellDragDown")

;---- Sidebar: icons only ---------------------------------------------------------------------------

Gui, Add, Text, x0 y0 w%SIDEW% h%WINH% HwndhSidebarBG
SpecialBrushes[hSidebarBG] := {brush: hBrushPanel, text: ColorTextBGR}
SideLineX := SIDEW
Gui, Add, Text, x%SideLineX% y0 w1 h%WINH% HwndhDiv1
SpecialBrushes[hDiv1] := {brush: hBrushBorder, text: ColorTextBGR}

Gui, Font, s15 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x10 y8 w44 h40 Center +0x200 HwndhLogoTile, 🐟
SpecialBrushes[hLogoTile] := {brush: hBrushPanel, text: ColorTextBGR}

NavDefs := [ ["ReadThis","⚠  READ THIS"], ["Home","🏠  Fishing"], ["General","🎣  General"], ["Cast","🎯  Cast"], ["Shake","🐚  Shake"]
	, ["Minigame","🎮  Minigame"], ["Utilities","🧰  Utilities"], ["Misc","🧩  Miscellaneous"]
	, ["Faq","❓  FAQ"], ["About","ℹ️  About"] ]

NavY := 62
for i, d in NavDefs
	{
	nk := d[1]
	np := StrSplit(d[2], "  ")
	nl := np[1]
	BarY := NavY + 10
	Gui, Add, Text, x2 y%BarY% w3 h20 vNavBar%nk% HwndhNB
	SpecialBrushes[hNB] := {brush: hBrushPanel, text: ColorTextBGR}
	RoundCtrl(hNB, 3, 20, 2)
	NavHwnd["bar" . nk] := hNB
	Gui, Font, s13 Norm c%ColorText%, Segoe UI
	Gui, Add, Text, x10 y%NavY% w44 h40 Center +0x200 vNav%nk% gSidebarClick HwndhNV, %nl%
	RoundCtrl(hNV, 44, 40, 10)
	SpecialBrushes[hNV] := {brush: hBrushPanel, text: (nk = "ReadThis") ? ColorRedBGR : ColorNavBGR}
	IconTips[hNV] := Trim(np[2])
	NavHwnd[nk] := hNV
	NavY += 46
	}

Gui, Font, s12 Norm c%ColorAccent%, Segoe UI
AddKeyBtnY := WINH - 100
Gui, Add, Text, x10 y%AddKeyBtnY% w44 h40 Center +0x100 +0x200 gAddKeyClick HwndhAddKeyBtn, 🔑
SpecialBrushes[hAddKeyBtn] := {brush: hBrushPanel, text: ColorAccentBGR}
RoundCtrl(hAddKeyBtn, 44, 40, 10)
IconTips[hAddKeyBtn] := "Add key"
Gui, Font, s12 Norm c%ColorRed%, Segoe UI
VersionsBtnY := WINH - 54
Gui, Add, Text, x10 y%VersionsBtnY% w44 h40 Center +0x100 +0x200 gVersionsClick HwndhVersionsBtn, 📜
SpecialBrushes[hVersionsBtn] := {brush: hBrushPanel, text: ColorRedBGR}
RoundCtrl(hVersionsBtn, 44, 40, 10)
IconTips[hVersionsBtn] := "Versions  (F9 = Colors)"

Gui, Font, s9 Bold c%ColorMuted%, Segoe UI
MtX := CARDX - XS
MtY := 122 - YS
Gui, Add, Text, x%MtX% y%MtY% w150 h30 Center +0x100 +0x200 vMiniTabSetup gMiniTabClick HwndhMT, Setup
MiniTabSetupH := hMT
RoundCtrl(hMT, 150, 30, 8)
MtX2 := 336 - XS
Gui, Add, Text, x%MtX2% y%MtY% w170 h30 Center +0x100 +0x200 vMiniTabColors gMiniTabClick HwndhMT, Color Manager
MiniTabColorsH := hMT
RoundCtrl(hMT, 170, 30, 8)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

AllManaged := []
NeedSection := "General"
gosub, EnsureSection

TargetSection := ReadThisAccepted ? "Home" : "ReadThis"
gosub, ApplyCastModeLocks
gosub, ShowSection

if (GuiAlwaysOnTop)
	Gui, +AlwaysOnTop

RoundCtrl(hStartStopBtnHwnd, 84, 30, 9)
ThemeCtl(hProfileSelect)
ThemeCtl(hMgCodeBox)
darkAttr := 1
DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiHwnd, "Int", 20, "Int*", darkAttr, "Int", 4)
DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiHwnd, "Int", 19, "Int*", darkAttr, "Int", 4)
cornerPref := (GuiCorners = "Square") ? 1 : ((GuiCorners = "Subtle") ? 3 : 2)
DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiHwnd, "Int", 33, "Int*", cornerPref, "Int", 4)

SbX := WINW - 15
Gui, Add, Text, x%SbX% y158 w9 h200 HwndSbTrack
SpecialBrushes[SbTrack] := {brush: hBrushSbTrack, text: 0xFFFFFF}
Gui, Add, Text, x%SbX% y158 w9 h60 HwndSbThumb
SpecialBrushes[SbThumb] := {brush: hBrushSbThumb, text: 0xFFFFFF}
DllCall("SetWindowPos", "Ptr", SbThumb, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)
GuiControl, 1:Hide, %SbTrack%
GuiControl, 1:Hide, %SbThumb%

Gui, Show, w%WINW% h%WINH%, DeepFish BETA
SetTimer, HeaderStatsTick, 1000
HideHelpIcons()
RoundExtras()
SetTimer, InfoPanelTick, 500
SetTimer, FishScanTick, 450
SetTimer, DFCheckForUpdate, -1200
SetTimer, OverlayHideTick, 250
gosub, RepaintGui

return

;====================================================================================================;

EnsureSection:
if (SectionBuilt.HasKey(NeedSection))
	return
SectionBuilt[NeedSection] := 1
ThemedMark := ThemedCtrls.MaxIndex()
if (!ThemedMark)
	ThemedMark := 0
NewLists := []
if (NeedSection = "General")
	{
	gosub, BuildGeneralSection
	NewLists := [GeneralCtrls]
	}
else if (NeedSection = "Home")
	{
	gosub, BuildHomeSection
	NewLists := [HomeCtrls]
	}
else if (NeedSection = "Cast")
	{
	gosub, BuildCastSection
	NewLists := [CastCtrls, NormalCastCtrls, PerfectCastCtrls]
	}
else if (NeedSection = "Shake")
	{
	gosub, BuildShakeSection
	NewLists := [ShakeCtrls]
	}
else if (NeedSection = "Minigame")
	{
	gosub, BuildMinigameSection
	gosub, BuildColorManagerSection
	NewLists := [MgAllCtrls, CMCtrls]
	}
else if (NeedSection = "Utilities")
	{
	gosub, BuildUtilitiesSection
	NewLists := [UtilCtrls]
	}
else if (NeedSection = "Totem")
	{
	gosub, BuildTotemSection
	NewLists := [TotemCtrls]
	}
else if (NeedSection = "Misc")
	{
	gosub, BuildMiscSection
	NewLists := [MiscCtrls]
	}
else if (NeedSection = "Aquarium")
	{
	gosub, BuildAquariumSection
	NewLists := [AquariumCtrls]
	}
else if (NeedSection = "Keeper")
	{
	gosub, BuildKeeperSection
	NewLists := [KeeperCtrls]
	}
else if (NeedSection = "Advanced")
	{
	gosub, BuildAdvancedSection
	NewLists := [AdvCtrls]
	}
else if (NeedSection = "Guess")
	{
	gosub, BuildGuessSection
	NewLists := [GuessCtrls]
	}
else if (NeedSection = "Webhook")
	{
	gosub, BuildWebhookSection
	NewLists := [WebhookCtrls]
	}
else if (NeedSection = "Faq")
	{
	gosub, BuildFaqSection
	NewLists := [FaqCtrls]
	}
else if (NeedSection = "About")
	{
	gosub, BuildAboutSection
	NewLists := [AboutCtrls]
	}
else if (NeedSection = "Versions")
	{
	gosub, BuildVersionsSection
	NewLists := [VersionsCtrls]
	}
else if (NeedSection = "ReadThis")
	{
	gosub, BuildReadThisSection
	NewLists := [ReadThisCtrls]
	}
else
	return

for i, lst in NewLists
	{
	FixCardBrushes(lst)
	ShiftCtrls(lst, (NeedSection = "General") ? GenProfN : 0)
	SnapshotBase(lst)
	for j, h in lst
		AllManaged.Push(h)
	}
tk := ThemedMark + 1
tn := ThemedCtrls.MaxIndex()
while (tk <= tn)
	{
	ThemeCtl(ThemedCtrls[tk])
	tk++
	}
HideHelpIcons()
RoundExtras()
if (NeedSection = "Minigame")
	gosub, RefreshControlModes
if (NeedSection = "Cast")
	gosub, ApplyCastModeLocks
return

RepaintGui:
DllCall("RedrawWindow", "Ptr", GuiHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
return

HeaderStatsTick:
if (!hHeaderStats)
	return
if (!WhStartTick or !MacroRunning)
	HsTxt := MacroRunning ? "starting..." : ""
else
	{
	HsMs := A_TickCount - WhStartTick
	HsHr := HsMs / 3600000.0
	HsRate := (HsHr > 0.01) ? Round(CaughtTotal() / HsHr) : 0
	HsMin := HsMs // 60000
	HsTxt := "🐟 " . CaughtTotal() . "  ·  " . HsRate . "/hr  ·  " . (HsMin // 60) . "h " . Mod(HsMin, 60) . "m"
	}
if (HsTxt != HsLast)
	{
	HsLast := HsTxt
	GuiControl, 1:, HeaderStats, %HsTxt%
	}
return

RefreshRunChip:
gosub, SyncRunKeys
if (!hRunStatus)
	return
if (MacroRunning)
	{
	SpecialBrushes[hRunStatus] := {brush: hBrushGreen, text: 0x101010}
	GuiControl, 1:, RunStatusText, ●  Running
	}
else
	{
	SpecialBrushes[hRunStatus] := {brush: hBrushPanel, text: ColorMutedBGR}
	GuiControl, 1:, RunStatusText, ●  Idle
	}
DllCall("RedrawWindow", "Ptr", hRunStatus, "Ptr", 0, "Ptr", 0, "UInt", 0x0005)
return

;====================================================================================================;

BuildHomeSection:
HmX := CARDX
HmW := CARDW
HmColW := (HmW - 14) // 2
HmX2 := HmX + HmColW + 14
HmRowH := 36

Gui, Font, s18 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%HmX% y128 w300 h36 HwndhC, Fishing
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}

; ---- Status + Statistics cards
Gui, Font, s9 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%HmX% y174 w200 h18 HwndhC, Status
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}
Gui, Add, Text, x%HmX2% y174 w200 h18 HwndhC, Statistics
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}

HmCards := [[HmX, [["Phase", "HmPhase"], ["Progress", "HmProg"], ["Input", "HmInput"], ["Rod", "HmRod"]]]
	, [HmX2, [["Caught", "HmCaught"], ["Per hour", "HmRate"], ["Session", "HmSess"], ["Rod power", "HmPower"]]]]
for ci, card in HmCards
	{
	cx0 := card[1]
	rows := card[2]
	hC := AddPanel(cx0, 196, HmColW, rows.Length() * HmRowH + 4, 10)
	HomeCtrls.Push(hC)
	ry := 198
	for ri, r in rows
		{
		if (ri > 1)
			{
			sx := cx0 + 10
			sw := HmColW - 20
			Gui, Add, Text, x%sx% y%ry% w%sw% h1 HwndhC
			HomeCtrls.Push(hC)
			SpecialBrushes[hC] := {brush: hBrushBorder, text: ColorTextBGR}
			}
		lx := cx0 + 14
		ty := ry + 8
		Gui, Font, s10 Norm c%ColorText%, Segoe UI
		Gui, Add, Text, x%lx% y%ty% w130 h20 +0x200 HwndhC, % r[1]
		HomeCtrls.Push(hC)
		SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
		vx := cx0 + HmColW - 154
		vn := r[2]
		Gui, Font, s10 Norm c%ColorMuted%, Segoe UI
		Gui, Add, Text, x%vx% y%ty% w140 h20 Right +0x200 v%vn% HwndhC, ---
		HomeCtrls.Push(hC)
		SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
		ry += HmRowH
		}
	}

; ---- Configuration
Gui, Font, s9 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%HmX% y360 w200 h18 HwndhC, Configuration
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}
HmCfg := [ ["🎯   Casting Mode", "DashCast", "Normal|Perfect", "How the rod is cast (same as the Cast page)."]
	, ["🔁   Smart Cast", "DashSmart", "Off|On", "Recast straight away when a cast did not go through."]
	, ["👁   Passive Mode", "DashPassive", "Off|On", "Do not cast or shake - just play the minigame`nwhenever it shows up (every rod)."]
	, ["🫥   Hide Overlay", "DashHide", "Off|On", "Hide the info text and bar overlay while running."]
	, ["⏱   Adaptive Cast", "DashAdapt", "Off|On", "Cast a set number of ms after the minigame closes,`ninstead of a fixed restart delay. Set the ms in the`nbox next to it (150 is a good start, lower = faster).`n`nNegative values (like -150) cast even sooner: the`nmacro decides the fish is caught faster. Down to -250.`nWhile the fight's UI is still on screen it never ends`nthe fight early, so a flickering bar is safe.`n`nStellarwave: the fight already ends the moment its`nbar and stars are gone, so 0 is fast there."]
	, ["🐟   Fish Scanner", "DashScan", "Off|On", "Reads every ""You just caught a ... at ... kg!"" message`n(Extra! catches too) and works out each fish's value with`nthe Fischipedia Fish Value Calculator formula. Extra!`nfish are added to Caught. Shows on the info panel.`n`nNot 100`% accurate - values are estimates."]
	, ["🪟   Info Panel", "DashInfo", "Off|On", "A small always-on-top panel with your rod, phase,`ncatches, rate, session time and rod power.`nWhile it is on, it replaces the old text info`nin the corner.`n`nPlace it by dragging the box in the screen below."] ]
hC := AddPanel(HmX, 382, HmW, HmCfg.Length() * HmRowH + 4, 10)
HomeCtrls.Push(hC)
ry := 384
for ri, r in HmCfg
	{
	if (ri > 1)
		{
		sx := HmX + 10
		sw := HmW - 20
		Gui, Add, Text, x%sx% y%ry% w%sw% h1 HwndhC
		HomeCtrls.Push(hC)
		SpecialBrushes[hC] := {brush: hBrushBorder, text: ColorTextBGR}
		}
	lx := HmX + 14
	ty := ry + 8
	Gui, Font, s10 Norm c%ColorText%, Segoe UI
	Gui, Add, Text, x%lx% y%ty% w260 h20 +0x200 HwndhC, % r[1]
	HomeCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
	IconTips[hC] := r[4]
	dx := HmX + HmW - 194
	dy := ry + 6
	dv := r[2]
	Gui, Font, s9 Norm c%ColorText%, Segoe UI
	if (dv = "DashAdapt")
		{
		Gui, Add, Edit, x%dx% y%dy% w76 h24 vDashAcMs gDashAcMsChanged Limit6 HwndhC, %AdaptiveCastMs%
		HomeCtrls.Push(hC)
		ThemedCtrls.Push(hC)
		IconTips[hC] := "ms to wait after the minigame closes before casting (negative like -150 = cast sooner, down to -250)"
		dx2 := dx + 84
		Gui, Add, DropDownList, x%dx2% y%dy% w96 h120 v%dv% gDashChanged HwndhC, % r[3]
		}
	else
		Gui, Add, DropDownList, x%dx% y%dy% w180 h120 v%dv% gDashChanged HwndhC, % r[3]
	HomeCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	ry += HmRowH
	}
; ---- Info panel position: drag the box across the screen shape
Gui, Font, s9 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%HmX% y654 w300 h18 HwndhC, Info panel position
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}
hC := AddPanel(HmX, 676, HmW, 138, 10)
HomeCtrls.Push(hC)
InfoMonGet(ImL, ImT, ImW, ImH)
IpMonH := 110
IpMonW := Round(IpMonH * ImW / ImH)
if (IpMonW > 220)
	{
	IpMonW := 220
	IpMonH := Round(IpMonW * ImH / ImW)
	}
IpMonBX := HmX + 16
IpMonBY := 676 + (138 - IpMonH) // 2
IpBezX := IpMonBX - 3
IpBezY := IpMonBY - 3
IpBezW := IpMonW + 6
IpBezH := IpMonH + 6
Gui, Add, Text, x%IpBezX% y%IpBezY% w%IpBezW% h%IpBezH% HwndhIpBezel
HomeCtrls.Push(hIpBezel)
SpecialBrushes[hIpBezel] := {brush: hBrushBorder, text: ColorTextBGR}
RoundCtrl(hIpBezel, IpBezW, IpBezH, 6)
Gui, Add, Text, x%IpMonBX% y%IpMonBY% w%IpMonW% h%IpMonH% HwndhIpMon
HomeCtrls.Push(hIpMon)
RoundCtrl(hIpMon, IpMonW, IpMonH, 4)
SpecialBrushes[hIpMon] := {brush: hBrushBG, text: ColorTextBGR}
IpBoxW := Max(14, Round(IpMonW * InfoPanelPxW() / ImW))
IpBoxH := Max(10, Round(IpMonH * InfoPanelPxH() / ImH))
IpFx := InfoPanelX
IpFy := InfoPanelY
if IpFx is not number
	IpFx := 0.02
if IpFy is not number
	IpFy := 0.35
IpBoxX := IpMonBX + Round(IpFx * (IpMonW - IpBoxW))
IpBoxY := IpMonBY + Round(IpFy * (IpMonH - IpBoxH))
Gui, Add, Text, x%IpBoxX% y%IpBoxY% w%IpBoxW% h%IpBoxH% +0x100 gInfoBoxDrag HwndhIpBox
HomeCtrls.Push(hIpBox)
SpecialBrushes[hIpBox] := {brush: hBrushAccent, text: 0x101010}
RoundCtrl(hIpBox, IpBoxW, IpBoxH, 3)
IconTips[hIpBox] := "Drag me to where the info panel should sit on your screen."
IpTxX := IpMonBX + IpMonW + 24
IpTxW := HmX + HmW - IpTxX - 14
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%IpTxX% y694 w%IpTxW% h100 HwndhC, Drag the bright box around the screen shape - the info panel moves with it, live.`n`nIt shows on the screen Roblox is on. Turn it on with Info Panel above.
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}

; ---- Appearance
Gui, Font, s9 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%HmX% y832 w300 h18 HwndhC, Appearance
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}
ApOpts := [ ["🎨   Theme", "ApTheme", "Mono|Midnight|Violet|Emerald|Crimson|Classic", GuiTheme]
	, ["◻   Corners", "ApCorners", "Square|Subtle|Rounded|Extra round", GuiCorners]
	, ["▭   Inputs", "ApInputs", "Filled|Outlined", GuiInputs]
	, ["❔   Help icons", "ApHelp", "Show|Hide", GuiHelp] ]
hC := AddPanel(HmX, 854, HmW, ApOpts.Length() * HmRowH + 4, 10)
HomeCtrls.Push(hC)
ry := 856
for ri, r in ApOpts
	{
	if (ri > 1)
		{
		sx := HmX + 10
		sw := HmW - 20
		Gui, Add, Text, x%sx% y%ry% w%sw% h1 HwndhC
		HomeCtrls.Push(hC)
		SpecialBrushes[hC] := {brush: hBrushBorder, text: ColorTextBGR}
		}
	lx := HmX + 14
	ty := ry + 8
	Gui, Font, s10 Norm c%ColorText%, Segoe UI
	Gui, Add, Text, x%lx% y%ty% w260 h20 +0x200 HwndhC, % r[1]
	HomeCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
	dx := HmX + HmW - 194
	dy := ry + 6
	dv := r[2]
	ApIdx := 1
	Loop, Parse, % r[3], |
		{
		if (A_LoopField = r[4])
			ApIdx := A_Index
		}
	Gui, Font, s9 Norm c%ColorText%, Segoe UI
	Gui, Add, DropDownList, x%dx% y%dy% w180 h140 v%dv% gAppearanceChanged Choose%ApIdx% HwndhC, % r[3]
	HomeCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	ry += HmRowH
	}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%HmX% y1006 w%HmW% h18 HwndhC, Changing these restarts the window (your settings are saved first).
HomeCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}
return

AppearanceChanged:
GuiControlGet, ApV, 1:, %A_GuiControl%
if (ErrorLevel or ApV = "")
	return
ApKey := {"ApTheme": "Theme", "ApCorners": "Corners", "ApInputs": "Inputs", "ApHelp": "HelpIcons"}[A_GuiControl]
ApCur := {"ApTheme": GuiTheme, "ApCorners": GuiCorners, "ApInputs": GuiInputs, "ApHelp": GuiHelp}[A_GuiControl]
if (ApKey = "" or ApV = ApCur)
	return
IniWrite, %ApV%, %SettingsFile%, GUI, %ApKey%
if (MacroRunning)
	{
	MsgBox, 4160, DeepFish, Saved. It applies the next time the macro starts (it is running right now).
	return
	}
gosub, SaveSettings
Reload
return

InfoBoxDrag:
InfoMonGet(ImL, ImT, ImW, ImH)
CtrlSnapPos(hIpMon, IdMx, IdMy, IdMw, IdMh)
CtrlSnapPos(hIpBox, IdBx, IdBy, IdBw, IdBh)
InfoCursorGui(IdGx, IdGy)
IdOffX := IdGx - IdBx
IdOffY := IdGy - IdBy
IdWas := InfoPanelOn
if (!InfoPanelOn)
	InfoPanelOn := true
while KeyHeld("LButton")
	{
	InfoCursorGui(IdGx, IdGy)
	IdNx := IdGx - IdOffX
	IdNy := IdGy - IdOffY
	IdNx := (IdNx < IdMx) ? IdMx : ((IdNx > IdMx + IdMw - IdBw) ? IdMx + IdMw - IdBw : IdNx)
	IdNy := (IdNy < IdMy) ? IdMy : ((IdNy > IdMy + IdMh - IdBh) ? IdMy + IdMh - IdBh : IdNy)
	GuiControl, 1:Move, %hIpBox%, % "x" . IdNx . " y" . IdNy
	InfoPanelX := (IdMw > IdBw) ? Round((IdNx - IdMx) / (IdMw - IdBw), 4) : 0
	InfoPanelY := (IdMh > IdBh) ? Round((IdNy - IdMy) / (IdMh - IdBh), 4) : 0
	gosub, InfoPanelTick
	Sleep, 10
	}
InfoPanelOn := IdWas
SetBase(hIpBox, IpMonBX + (IdNx - IdMx), IpMonBY + (IdNy - IdMy))
DllCall("RedrawWindow", "Ptr", hIpMon, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
gosub, InfoPanelTick
gosub, QueueAutoSave
return

;---- the floating info panel ------------------------------------------------------------------------

InfoPanelTick:
if (!InfoPanelOn or OverlayHidden)
	{
	if (IpShown)
		{
		Gui, InfoP:Hide
		IpShown := false
		}
	return
	}
; the Signs row only exists for Stellarwave - rebuild when the rod changes
if (hInfoP and IpHasSw != (SpecialRod = "Stellarwave Melody"))
	{
	Gui, InfoP:Destroy
	hInfoP := 0
	IpShown := false
	Loop 12
		IpLast%A_Index% := ""
	}
if (!hInfoP)
	{
	Gui, InfoP:New, +AlwaysOnTop -Caption +ToolWindow +E0x20 +HwndhInfoP
	Gui, InfoP:Color, %ColorCard%
	Gui, InfoP:Margin, 0, 0
	Gui, InfoP:Font, s10 Bold c%ColorText%, Segoe UI
	Gui, InfoP:Add, Text, x14 y10 w200 h20 HwndhIpT, DeepFish
	SpecialBrushes[hIpT] := {brush: hBrushCard, text: ColorTextBGR}
	IpHasSw := (SpecialRod = "Stellarwave Melody")
	IpRows := ["Rod", "Phase", "Caught", "Per hour", "Session", "Rod power"]
	if (IpHasSw)
		IpRows.Push("Signs")
	if (FishScanOn)
		IpRows.Push("Fish seen", "Last fish", "Last value", "Session value")
	IpW := IpHasSw ? 320 : (FishScanOn ? 300 : 246)
	IpVw := IpW - 106
	IpY := 36
	for i, nm in IpRows
		{
		Gui, InfoP:Font, s9 Norm c%ColorMuted%, Segoe UI
		Gui, InfoP:Add, Text, x14 y%IpY% w86 h18 HwndhIpT, %nm%
		SpecialBrushes[hIpT] := {brush: hBrushCard, text: ColorMutedBGR}
		Gui, InfoP:Font, s9 Norm c%ColorText%, Segoe UI
		Gui, InfoP:Add, Text, x92 y%IpY% w%IpVw% h18 Right vIpVal%i% HwndhIpT, ---
		SpecialBrushes[hIpT] := {brush: hBrushCard, text: ColorTextBGR}
		IpY += 20
		}
	IpH := IpY + 8
	Gui, InfoP:Show, Hide w%IpW% h%IpH%, DeepFish Info
	DetectHiddenWindows, On
	WinGetPos, , , IpPw, IpPh, ahk_id %hInfoP%
	IpRad := Round(28 * ((GuiRoundMul = "") ? 1 : GuiRoundMul))
	if (IpRad > 1)
		WinSet, Region, % "0-0 w" . IpPw . " h" . IpPh . " R" . IpRad . "-" . IpRad, ahk_id %hInfoP%
	WinSet, Transparent, 236, ahk_id %hInfoP%
	Gui, 1:Default
	}
gosub, HomeCompute
IpNew := [HmV4, HmV1, HmV5, HmV6, HmV7, HmV8]
if (IpHasSw)
	IpNew.Push((SwPanelTxt = "") ? "waiting for signs" : SwPanelTxt)
if (FishScanOn)
	{
	IpNew.Push(FsCount . "")
	IpNew.Push((FsLastName = "") ? "---" : FsLastName . "  " . FsLastKg . "kg")
	IpNew.Push((FsLastName = "") ? "---" : ((FsLastVal < 0) ? "unknown fish" : FsMoney(FsLastVal) . " C$"))
	IpNew.Push(FsMoney(FsTotal) . " C$")
	}
for i, v in IpNew
	{
	if (IpLast%i% != v)
		{
		IpLast%i% := v
		GuiControl, InfoP:, IpVal%i%, %v%
		}
	}
InfoMonGet(ImL, ImT, ImW, ImH)
IpFx := InfoPanelX
IpFy := InfoPanelY
if IpFx is not number
	IpFx := 0.02
if IpFy is not number
	IpFy := 0.35
IpSx := Round(ImL + IpFx * (ImW - IpPw))
IpSy := Round(ImT + IpFy * (ImH - IpPh))
if (!IpShown or IpSx != IpLastX or IpSy != IpLastY)
	{
	Gui, InfoP:Show, x%IpSx% y%IpSy% NoActivate
	IpShown := true
	IpLastX := IpSx
	IpLastY := IpSy
	}
return


;---- Fish scanner: reads "You just caught a ... at ... kg!" and values each fish --------------------------

FishScanTick:
if (!FishScanOn or !MacroRunning or !RobloxHwnd)
	return
if (!FsReady or A_TickCount - FsDataChkT > 600000)
	{
	FsReady := true
	FsDataChkT := A_TickCount
	if (FsLoadData() and FsWorkerPid)
		{
		; new list downloaded - restart the reader so it uses it
		Process, Close, %FsWorkerPid%
		FsWorkerPid := 0
		}
	}
FsEnsureWorker()
FsOutF := A_Temp . "\deepfish_ocr_out.txt"
FsReqF := A_Temp . "\deepfish_ocr_req.txt"
if FileExist(FsOutF)
	{
	FileRead, FsTxt, *P65001 %FsOutF%
	FileDelete, %FsOutF%
	FsPending := false
	Loop, Parse, FsTxt, `n, `r
		{
		FsP := StrSplit(A_LoopField, "|")
		if (FsP[1] = "L" and FsP.Length() >= 6)
			FsObserve(FsP[3], FsP[4], FsP[5], FsP[6], FsP[7] = "E")
		}
	}
FsCommitDue()
if (FsPending and A_TickCount - FsReqT > 5000)
	FsPending := false
; the catch message shows after the fight - do not spend CPU on OCR while reeling
if (!FsPending and !MgInPlay)
	{
	RobloxClientRect(RobloxHwnd, FsX, FsY, FsW, FsH)
	if (FsW > 200 and FsH > 200)
		{
		FsRx := FsX + Round(FsW * 0.02)
		FsRy := FsY + Round(FsH * 0.10)
		FsRw := Round(FsW * 0.96)
		FsRh := Round(FsH * 0.80)
		FileDelete, %FsReqF%
		FileAppend, % FsRx . " " . FsRy . " " . FsRw . " " . FsRh . " " . A_TickCount, %FsReqF%
		FsPending := true
		FsReqT := A_TickCount
		}
	}
return

; one reading of a catch line from the OCR helper (it already voted between its 3 zoom levels)
FsObserve(fk, canon, kg, val, ex := false) {
	global FsGroups, FsDone
	if (!IsObject(FsGroups))
		FsGroups := []
	if (!IsObject(FsDone))
		FsDone := []
	now := A_TickCount
	dg := RegExReplace(kg, "[^0-9]")
	if (dg = "")
		return
	for i, d in FsDone
		{
		if (d.k = fk and FsDigNear(d.dg, dg) and now - d.t < 4000)
			{
			d.t := now
			return
			}
		}
	g := ""
	for i, e in FsGroups
		{
		if (e.k = fk and FsDigNear(e.dg, dg) and now - e.t < 2500)
			{
			g := e
			break
			}
		}
	if (!IsObject(g))
		{
		g := {k: fk, dg: dg, t: now, t0: now, n: 0, ex: 0, votes: {}, vals: {}}
		FsGroups.Push(g)
		}
	key := canon . "|" . kg
	g.votes[key] := (g.votes.HasKey(key) ? g.votes[key] : 0) + 1
	g.vals[key] := val
	g.n := g.n + 1
	if (ex)
		g.ex := g.ex + 1
	g.t := now
}

; count a fish once its readings agree (3 the same), or once its message is gone
FsCommitDue() {
	global FsGroups, FsDone, FsCount, FsTotal, FsLastName, FsLastKg, FsLastVal, FsExtraCount
	if (!IsObject(FsGroups))
		return
	now := A_TickCount
	i := FsGroups.Length()
	while (i >= 1)
		{
		g := FsGroups[i]
		bestK := ""
		bestN := -1
		for k, n in g.votes
			{
			if (n > bestN or (n = bestN and InStr(StrSplit(k, "|")[2], ".")))
				{
				bestN := n
				bestK := k
				}
			}
		if (g.n < 2 and now - g.t > 1500)
			{
			; seen in only one frame - a stray misread, not a fish
			FsGroups.RemoveAt(i)
			i--
			continue
			}
		if ((bestN >= 3 and bestN * 10 >= g.n * 6) or (g.n >= 2 and now - g.t > 1500) or now - g.t0 > 6000)
			{
			kp := StrSplit(bestK, "|")
			val := g.vals[bestK] + 0
			FsCount := FsCount + 1
			; most of its readings said "Extra!" -> a bonus fish on top of the fight
			if (g.ex * 2 >= g.n)
				FsExtraCount := FsExtraCount + 1
			FsLastName := (g.k = "?") ? "unknown fish" : kp[1]
			FsLastKg := kp[2]
			FsLastVal := val
			if (val > 0)
				FsTotal := FsTotal + val
			FsDone.Push({k: g.k, dg: g.dg, t: g.t})
			FsGroups.RemoveAt(i)
			}
		i--
		}
	if (IsObject(FsDone))
		{
		i := FsDone.Length()
		while (i >= 1)
			{
			if (now - FsDone[i].t > 10000)
				FsDone.RemoveAt(i)
			i--
			}
		}
}

; every fight is one fish; the scanner adds the "Extra!" bonus fish on top
CaughtTotal() {
	global WhCatches, FishScanOn, FsExtraCount
	return Round(WhCatches) + (FishScanOn ? Round(FsExtraCount) : 0)
}

FsDigNear(a, b) {
	if (a = b)
		return true
	if (Abs(StrLen(a) - StrLen(b)) > 1)
		return false
	return (FsLev(a, b) <= 1)
}

; value = ceil( ceil(base_value / base_weight * kg) * mutation * attributes )   (Fischipedia Fish Value Calculator)
FsValue(name, kg, ByRef canon := "") {
	global FsFish, FsFishName
	canon := ""
	if (!IsObject(FsFish) or !FsFish.Count())
		return -1
	w := StrSplit(name, " ")
	n := w.Length()
	pick := 0
	pickMult := 1
	pickFish := ""
	pickPre := ""
	firstFish := 0
	; exact fish name at the end, words in front = mutations (fuzzy)
	Loop % n
		{
		k := A_Index
		cand := FsJoin(w, k, n)
		if (!FsFish.HasKey(Format("{:L}", cand)))
			continue
		if (!firstFish)
			firstFish := k
		mult := FsMutMult(w, k - 1, ok, pre)
		if (ok)
			{
			pick := k
			pickMult := mult
			pickFish := Format("{:L}", cand)
			pickPre := pre
			break
			}
		}
	if (!pick and firstFish)
		{
		pick := firstFish
		pickFish := Format("{:L}", FsJoin(w, firstFish, n))
		pickMult := FsMutMult(w, firstFish - 1, ok, pickPre)
		}
	; no exact fish: closest fish name (OCR typo), longest suffix first
	if (!pick)
		{
		Loop % (n < 3) ? n : 3
			{
			k := n - ((n < 3) ? n : 3) + A_Index
			cand := Format("{:L}", FsJoin(w, k, n))
			best := FsClosest(cand, FsFish)
			if (best != "")
				{
				pick := k
				pickFish := best
				pickMult := FsMutMult(w, k - 1, ok, pickPre)
				break
				}
			}
		}
	if (!pick)
		return -1
	f := FsFish[pickFish]
	canon := Trim(pickPre . " " . (FsFishName.HasKey(pickFish) ? FsFishName[pickFish] : pickFish))
	if (f[2] <= 0)
		return -1
	wp := Ceil(f[1] / f[2] * kg)
	return Ceil(wp * pickMult)
}

FsJoin(w, a, b) {
	s := ""
	Loop % b - a + 1
		s .= ((A_Index > 1) ? " " : "") . w[a + A_Index - 1]
	return s
}

; closest key in obj within a small typo distance, or ""
FsClosest(word, obj) {
	len := StrLen(word)
	tol := (len >= 9) ? 2 : ((len >= 4) ? 1 : 0)
	if (!tol)
		return ""
	best := ""
	bd := 99
	for k, v in obj
		{
		if (Abs(StrLen(k) - len) > tol)
			continue
		d := FsLev(word, k)
		if (d < bd)
			{
			bd := d
			best := k
			}
		}
	return (bd <= tol) ? best : ""
}

FsLev(a, b) {
	la := StrLen(a)
	lb := StrLen(b)
	prev := []
	Loop % lb + 1
		prev.Push(A_Index - 1)
	Loop % la
		{
		i := A_Index
		ca := SubStr(a, i, 1)
		cur := [i]
		Loop % lb
			{
			j := A_Index
			cost := (ca == SubStr(b, j, 1)) ? 0 : 1
			cur.Push(Min(prev[j + 1] + 1, cur[j] + 1, prev[j] + cost))
			}
		prev := cur
		}
	return prev[lb + 1]
}

; multiplies the mutation / Shiny / Sparkling words in front of the fish name (longest names first, typos allowed)
FsMutMult(w, cnt, ByRef ok, ByRef names := "") {
	global FsMut, FsMutName
	ok := true
	mult := 1
	names := ""
	i := 1
	while (i <= cnt)
		{
		hit := ""
		L := (cnt - i + 1 < 3) ? cnt - i + 1 : 3
		while (L >= 1)
			{
			ph := Format("{:L}", FsJoin(w, i, i + L - 1))
			if (IsObject(FsMut) and FsMut.HasKey(ph))
				hit := ph
			else if (IsObject(FsMut))
				hit := FsClosest(ph, FsMut)
			if (hit != "")
				break
			L--
			}
		if (hit != "")
			{
			mult := mult * FsMut[hit]
			names .= ((names = "") ? "" : " ") . (FsMutName.HasKey(hit) ? FsMutName[hit] : hit)
			i += L
			}
		else
			{
			ok := false
			i++
			}
		}
	return mult
}

FsLoadData() {
	global FsFish, FsMut, FsFishName, FsMutName
	FsFish := {}
	FsMut := {}
	FsFishName := {}
	FsMutName := {}
	f := A_ScriptDir . "\FischFishData.txt"
	got := false
	; the list is kept for good and only replaced once a week - after Monday 6 PM US Eastern
	if (FsDataStale(f))
		{
		fj := FsFetch("bucket('fish').select('name','base_weight','base_value').limit(5000).run()")
		mj := FsFetch("bucket('mutations').select('name','value').limit(5000).run()")
		if (fj != "" and mj != "")
			{
			out := ""
			pos := 1
			while (pos := RegExMatch(fj, "O)\{[^{}]*\}", mo, pos))
				{
				obj := mo.Value(0)
				pos += mo.Len(0)
				if (RegExMatch(obj, """name""\s*:\s*""([^""]*)""", nm) and RegExMatch(obj, """base_value""\s*:\s*([0-9.]+)", bv) and RegExMatch(obj, """base_weight""\s*:\s*([0-9.]+)", bw))
					out .= "F|" . nm1 . "|" . bv1 . "|" . bw1 . "`n"
				}
			pos := 1
			while (pos := RegExMatch(mj, "O)\{[^{}]*\}", mo, pos))
				{
				obj := mo.Value(0)
				pos += mo.Len(0)
				if (RegExMatch(obj, """name""\s*:\s*""([^""]*)""", nm) and RegExMatch(obj, """value""\s*:\s*\[?\s*([0-9.]+)", mv))
					out .= "M|" . nm1 . "|" . mv1 . "`n"
				}
			if (StrLen(out) > 1000)
				{
				FileDelete, %f%
				FileAppend, %out%, %f%, UTF-8
				got := true
				}
			}
		}
	return got
	FileRead, txt, *P65001 %f%
	Loop, Parse, txt, `n, `r
		{
		p := StrSplit(A_LoopField, "|")
		if (p[1] = "F" and p.Length() >= 4)
			{
			FsFish[Format("{:L}", p[2])] := [p[3] + 0, p[4] + 0]
			FsFishName[Format("{:L}", p[2])] := p[2]
			}
		else if (p[1] = "M" and p.Length() >= 3)
			{
			FsMut[Format("{:L}", p[2])] := p[3] + 0
			FsMutName[Format("{:L}", p[2])] := p[2]
			}
		}
}

; true when there is no list yet, or the newest Monday 6 PM US Eastern is after the list was downloaded
FsDataStale(f) {
	if !FileExist(f)
		return true
	; the file's time in UTC
	FileGetTime, ft, %f%, M
	off := A_Now
	EnvSub, off, %A_NowUTC%, Seconds
	EnvAdd, ft, % -off, Seconds
	; now in US Eastern (EDT from the 2nd Sunday of March to the 1st Sunday of November)
	et := A_NowUTC
	eo := FsEasternOffset(A_NowUTC)
	EnvAdd, et, %eo%, Hours
	FormatTime, wd, %et%, WDay
	back := Mod(wd - 2 + 7, 7)
	bnd := SubStr(et, 1, 8) . "180000"
	EnvAdd, bnd, % -back, Days
	if (bnd > et)
		EnvAdd, bnd, -7, Days
	; back to UTC
	EnvAdd, bnd, % -eo, Hours
	return (ft < bnd)
}

FsEasternOffset(utc) {
	y := SubStr(utc, 1, 4)
	FormatTime, w1, %y%0301, WDay
	mar := 1 + Mod(8 - w1, 7) + 7
	FormatTime, w2, %y%1101, WDay
	nov := 1 + Mod(8 - w2, 7)
	dstOn := y . "03" . Format("{:02}", mar) . "070000"
	dstOff := y . "11" . Format("{:02}", nov) . "060000"
	return (utc >= dstOn and utc < dstOff) ? -4 : -5
}

FsFetch(q) {
	enc := ""
	Loop, Parse, q
		{
		c := A_LoopField
		if c is alnum
			enc .= c
		else if (InStr("-_.~", c))
			enc .= c
		else
			enc .= "%" . Format("{:02X}", Asc(c))
		}
	try
		{
		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.SetTimeouts(5000, 5000, 8000, 15000)
		whr.Open("GET", "https://fischipedia.org/w/api.php?action=bucket&format=json&query=" . enc, false)
		whr.SetRequestHeader("User-Agent", "DeepFish-macro")
		whr.Send()
		if (whr.Status != 200)
			return ""
		return whr.ResponseText
		}
	catch e
		return ""
}

FsMoney(n) {
	if n is not number
		return n
	return RegExReplace(Round(n), "\G\d+?(?=(\d{3})+(?:\D|$))", "$0,")
}

FsEnsureWorker() {
	global FsWorkerPid
	if (FsWorkerPid)
		{
		Process, Exist, %FsWorkerPid%
		if (ErrorLevel)
			return
		}
	ps := A_Temp . "\deepfish_ocr_worker.ps1"
	FileDelete, %ps%
	FileAppend, % FsWorkerScript(), %ps%, UTF-8
	me := DllCall("GetCurrentProcessId")
	data := A_ScriptDir . "\FischFishData.txt"
	Run, powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%ps%" -ParentPid %me% -Dir "%A_Temp%" -Data "%data%", , Hide, FsWorkerPid
}

FsWorkerScript() {
ws1 =
(% Join`r`n
param([int]$ParentPid, [string]$Dir, [string]$Data = '', [string]$ImgFile = '', [switch]$Once)
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -Name D -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
[W.D]::SetProcessDPIAware() | Out-Null
$cs = @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
public static class FR {
    public class FishInfo { public string Name; public double BV; public double BW; }
    public static Dictionary<string, FishInfo> Fish = new Dictionary<string, FishInfo>();
    public static Dictionary<string, double> Mut = new Dictionary<string, double>();
    public static Dictionary<string, string> MutName = new Dictionary<string, string>();
    static List<string> FishKeys = new List<string>();
    static List<string> FishFlat = new List<string>();
    static List<string> MutKeys = new List<string>();
    static Regex LineRx = new Regex(@"c\S{2,6}t\s+an?\s+(.+?)\s+(?:a\S{0,2}\s+)?(\d[\d.,]*(?:\s\d{1,2}(?=\s*k))?)\s*k\s*g", RegexOptions.IgnoreCase);

    public static void Load(string path) {
        Fish.Clear(); Mut.Clear(); MutName.Clear(); FishKeys.Clear(); FishFlat.Clear(); MutKeys.Clear();
        if (!File.Exists(path)) return;
        foreach (string line in File.ReadAllLines(path, Encoding.UTF8)) {
            string[] p = line.Split('|');
            double a, b;
            if (p.Length >= 4 && p[0] == "F" && double.TryParse(p[2], NumberStyles.Float, CultureInfo.InvariantCulture, out a) && double.TryParse(p[3], NumberStyles.Float, CultureInfo.InvariantCulture, out b)) {
                string k = N(p[1]);
                if (k.Length > 0 && !Fish.ContainsKey(k)) { Fish[k] = new FishInfo { Name = p[1], BV = a, BW = b }; FishKeys.Add(k); FishFlat.Add(k.Replace(" ", "")); }
            } else if (p.Length >= 3 && p[0] == "M" && double.TryParse(p[2], NumberStyles.Float, CultureInfo.InvariantCulture, out a)) {
                string k = N(p[1]);
                if (k.Length > 0 && !Mut.ContainsKey(k)) { Mut[k] = a; MutName[k] = p[1]; MutKeys.Add(k); }
            }
        }
    }
    public static string N(string s) {
        s = s.ToLowerInvariant().Replace("'", "").Replace("\u2019", "").Replace("-", " ");
        s = Regex.Replace(s, "[^a-z0-9 ]", "");
        return Regex.Replace(s, @"\s+", " ").Trim();
    }
    public static int Lev(string a, string b) {
        int[] prev = new int[b.Length + 1], cur = new int[b.Length + 1];
        for (int j = 0; j <= b.Length; j++) prev[j] = j;
        for (int i = 1; i <= a.Length; i++) {
            cur[0] = i;
            for (int j = 1; j <= b.Length; j++) {
                int c = a[i - 1] == b[j - 1] ? 0 : 1;
                cur[j] = Math.Min(Math.Min(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + c);
            }
            int[] t = prev; prev = cur; cur = t;
        }
        return prev[b.Length];
    }
    static int Tol(int len) { return len >= 16 ? 3 : (len >= 9 ? 2 : (len >= 4 ? 1 : 0)); }
    // closest fish to a phrase (spaces optional, so glued/split words still match); cost = letters wrong
    static string FishMatch(string ph, out int cost) {
        cost = 99;
        if (ph.Length == 0) return null;
        if (Fish.ContainsKey(ph)) { cost = 0; return ph; }
        string flat = ph.Replace(" ", "");
        int tol = Tol(flat.Length);
        string best = null;
        for (int i = 0; i < FishFlat.Count; i++) {
            string k = FishFlat[i];
            if (k == flat) { cost = 0; return FishKeys[i]; }
            if (tol == 0 || Math.Abs(k.Length - flat.Length) > tol) continue;
            int d = Lev(flat, k);
            if (d < cost) { cost = d; best = FishKeys[i]; }
        }
        if (cost > tol) { cost = 99; return null; }
        return best;
    }
    static string MutMatch(string ph, out int cost) {
        cost = 99;
        if (Mut.ContainsKey(ph)) { cost = 0; return ph; }
        string flat = ph.Replace(" ", "");
        int tol = flat.Length >= 12 ? 3 : (flat.Length >= 7 ? 2 : (flat.Length >= 4 ? 1 : 0));
        if (tol == 0) return null;
        string best = null;
        foreach (string k in MutKeys) {
            string kf = k.Replace(" ", "");
            if (Math.Abs(kf.Length - flat.Length) > tol) continue;
            int d = Lev(flat, kf);
            if (d < cost) { cost = d; best = k; }
        }
        if (cost > tol) { cost = 99; return null; }
        return best;
    }
    // explain the words in front of the fish as mutations; unexplained words cost 4 each
    static int Prefix(List<string> p, out double mult, out string names) {
        int n = p.Count;
        int[] bc = new int[n + 1]; double[] bm = new double[n + 1]; string[] bn = new string[n + 1];
        for (int i = 1; i <= n; i++) bc[i] = 9999;
        bc[0] = 0; bm[0] = 1; bn[0] = "";
        for (int i = 0; i < n; i++) {
            if (bc[i] >= 9999) continue;
            for (int L = 1; L <= 3 && i + L <= n; L++) {
                int c; string hit = MutMatch(string.Join(" ", p.GetRange(i, L)), out c);
                if (hit != null && bc[i] + c < bc[i + L]) { bc[i + L] = bc[i] + c; bm[i + L] = bm[i] * Mut[hit]; bn[i + L] = (bn[i] + " " + MutName[hit]).Trim(); }
            }
            // two mutations glued into one word ("FrightfulMagmatic")
            string wd = p[i];
            if (wd.Length >= 8) {
                for (int s = 3; s <= wd.Length - 3; s++) {
                    int c1, c2; string m1 = MutMatch(wd.Substring(0, s), out c1); if (m1 == null) continue;
                    string m2 = MutMatch(wd.Substring(s), out c2); if (m2 == null) continue;
                    int c = c1 + c2 + 1;
                    if (bc[i] + c < bc[i + 1]) { bc[i + 1] = bc[i] + c; bm[i + 1] = bm[i] * Mut[m1] * Mut[m2]; bn[i + 1] = (bn[i] + " " + MutName[m1] + " " + MutName[m2]).Trim(); }
                }
            }
            if (bc[i] + 4 < bc[i + 1]) { bc[i + 1] = bc[i] + 4; bm[i + 1] = bm[i]; bn[i + 1] = bn[i]; }
        }
        mult = bm[n]; names = bn[n];
        return bc[n];
    }
    static void Try(List<string> pre, string fishPh, ref int bestCost, ref string bFish, ref string bCanon, ref double bMult, int extra) {
        int fc; string f = FishMatch(fishPh, out fc);
        if (f == null) return;
        double m; string mn; int pc = Prefix(pre, out m, out mn);
        int cost = fc * 2 + pc + extra;
        // tie: the longer fish name explains more of the text
        if (cost < bestCost || (cost == bestCost && bFish != null && f.Length > bFish.Length)) {
            bestCost = cost; bFish = f; bMult = m; bCanon = (mn + " " + Fish[f].Name).Trim();
        }
    }
    public static int Resolve(string raw, out string fishKey, out string canon, out double mult) {
        fishKey = null; canon = ""; mult = 1;
        int bestCost = 9999;
        if (Fish.Count == 0) return bestCost;
        string c = Regex.Replace(raw, "[,.\u2019'\"]", "").Replace("-", " ");
        var variants = new List<string> { c };
        string camel = Regex.Replace(c, "([a-z])([A-Z])", "$1 $2");
        if (camel != c) variants.Add(camel);
        string swap = c.Replace("rn", "m").Replace("vv", "w").Replace("cl", "d").Replace("1", "l").Replace("0", "o");
        if (swap != c) variants.Add(swap);
        for (int v = 0; v < variants.Count; v++) {
            string[] w = N(variants[v]).Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            int n = w.Length; if (n == 0) continue;
            int extra = v * 1;
            for (int k = 0; k < n; k++) {
                var pre = new List<string>(); for (int i = 0; i < k; i++) pre.Add(w[i]);
                Try(pre, string.Join(" ", w, k, n - k), ref bestCost, ref fishKey, ref canon, ref mult, extra);
            }
            // last word holds mutation + fish glued together ("Parpdiserrout")
            string last = w[n - 1];
            if (last.Length >= 7) {
                for (int s = 3; s <= last.Length - 3; s++) {
                    var pre = new List<string>(); for (int i = 0; i < n - 1; i++) pre.Add(w[i]); pre.Add(last.Substring(0, s));
                    Try(pre, last.Substring(s), ref bestCost, ref fishKey, ref canon, ref mult, extra + 1);
                }
            }
        }
        return bestCost;
    }
    static double ParseKg(string t) {
        t = t.Trim().TrimEnd('.');
        if (t.Contains(" ") && !t.Contains(".")) t = t.Replace(" ", ".");
        t = t.Replace(" ", "");
        if (t.Contains(",") && t.Contains(".")) t = t.Replace(",", "");
        else if (t.Contains(",")) t = Regex.IsMatch(t, @"^\d{1,3}(,\d{3})+$") ? t.Replace(",", "") : t.Replace(",", ".");
        double v; return double.TryParse(t, NumberStyles.Float, CultureInfo.InvariantCulture, out v) ? v : -1;
    }
    public static long Value(string fishKey, double kg, double mult) {
        FishInfo f = Fish[fishKey];
        if (f.BW <= 0) return -1;
        double wp = Math.Ceiling(f.BV / f.BW * kg);
        return (long)Math.Ceiling(wp * mult);
    }
    // one OCR line -> "fishKey|canon|kg|mult|cost" ("?|name|kg|1|99" when the fish is unknown), null if not a catch line
    public static string Read(string text) {
        text = Regex.Replace(text, @"(?<=\d)\s*([.,])\s*(?=[\dOo])", "$1");
        text = Regex.Replace(text, @"(?<=\d[.,]?)[Oo](?=[\dOo]*\s*k)", "0");
        text = Regex.Replace(text, @"(?<=\d[.,]?)[Oo](?=[\dOo]*\s*k)", "0");
        text = Regex.Replace(text, @"(?<=\d[.,]?)[lI](?=[\d]*\s*k)", "1");
        Match m = LineRx.Match(text);
        if (!m.Success) return null;
        string kgTxt = m.Groups[2].Value;
        double kg = ParseKg(kgTxt);
        if (kg <= 0) return null;
        string fk, canon; double mult;
        int cost = Resolve(m.Groups[1].Value, out fk, out canon, out mult);
        if (fk != null && cost < 12) {
            FishInfo f = Fish[fk];
            if (!kgTxt.Contains(".") && !kgTxt.Contains(",") && !kgTxt.Contains(" ") && f.BW > 0 && kg / f.BW > 25) {
                foreach (double d in new double[] { 10, 100 }) { if (kg / d / f.BW <= 25 && kg / d / f.BW >= 0.02) { kg = kg / d; break; } }
            }
            return fk + "|" + canon + "|" + kg.ToString(CultureInfo.InvariantCulture) + "|" + mult.ToString(CultureInfo.InvariantCulture) + "|" + cost;
        }
        return "?|" + N(m.Groups[1].Value) + "|" + kg.ToString(CultureInfo.InvariantCulture) + "|1|99";
    }
    // all readings of one line (weight: 1 = enlarged pass, 0.5 = rough pass) -> "fishKey|canon|kg|value"
    public static string Best(List<string> reads, List<double> weights) {
        var nameScore = new Dictionary<string, double>();
)
ws2 =
(% Join`r`n
        var kgScore = new Dictionary<string, double>();
        var multOf = new Dictionary<string, double>();
        string unknown = null;
        for (int i = 0; i < reads.Count; i++) {
            string r = reads[i]; if (string.IsNullOrEmpty(r) || r.Split('|').Length < 5) continue;
            string[] q = r.Split('|');
            double wgt = weights[i];
            int cost = int.Parse(q[4]);
            double kq = wgt * (cost >= 99 ? 0.5 : 1.0);
            double ks; kgScore.TryGetValue(q[2], out ks); kgScore[q[2]] = ks + kq + (q[2].Contains(".") ? 0.01 : 0);
            if (q[0] == "?") { if (unknown == null) unknown = q[1]; continue; }
            string key = q[0] + "|" + q[1];
            double s; nameScore.TryGetValue(key, out s); nameScore[key] = s + wgt * 12.0 / (1 + cost);
            multOf[key] = double.Parse(q[3], CultureInfo.InvariantCulture);
        }
        string bestKg = null; double bk = -1;
        foreach (var kv in kgScore) if (kv.Value > bk) { bk = kv.Value; bestKg = kv.Key; }
        if (bestKg == null) return null;
        var adj = new Dictionary<string, double>(nameScore);
        foreach (var A in nameScore) {
            if (A.Value < 4) continue;
            string ca = " " + A.Key.Split('|')[1].ToLowerInvariant();
            foreach (var B in nameScore) {
                if (B.Key == A.Key) continue;
                string cb = " " + B.Key.Split('|')[1].ToLowerInvariant();
                if (ca.Length > cb.Length && ca.EndsWith(cb)) adj[A.Key] += B.Value;
            }
        }
        string bestName = null; double bn = -1;
        foreach (var kv in adj) if (kv.Value > bn) { bn = kv.Value; bestName = kv.Key; }
        double kg = double.Parse(bestKg, CultureInfo.InvariantCulture);
        if (bestName == null) return "?|" + unknown + "|" + bestKg + "|-1";
        string fk = bestName.Split('|')[0];
        return bestName + "|" + bestKg + "|" + Value(fk, kg, multOf[bestName]);
    }
}
'@
Add-Type -TypeDefinition $cs -Language CSharp
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Media.Ocr.OcrResult, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics, ContentType = WindowsRuntime]
$null = [Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime]
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -like 'IAsyncOperation*' })[0]
function Await($op, [Type]$t) { $m = $asTask.MakeGenericMethod($t); $task = $m.Invoke($null, @($op)); $task.Wait(-1) | Out-Null; $task.Result }
$engine = $null
try { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new('en-US')) } catch { }
if (-not $engine) { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages() }
$maxDim = [Windows.Media.Ocr.OcrEngine]::MaxImageDimension - 10
$req = Join-Path $Dir 'deepfish_ocr_req.txt'
$out = Join-Path $Dir 'deepfish_ocr_out.txt'
$nl = [Environment]::NewLine
$dataStamp = $null
function LoadData() {
  if ($Data -and (Test-Path $Data)) {
    $st = (Get-Item $Data).LastWriteTimeUtc
    if ($st -ne $script:dataStamp) { [FR]::Load($Data); $script:dataStamp = $st }
  }
}
function Recognize($bmp) {
  $ms = New-Object System.IO.MemoryStream
  $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Bmp)
  $ms.Position = 0
  $ras = [System.IO.WindowsRuntimeStreamExtensions]::AsRandomAccessStream($ms)
  $dec = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($ras)) ([Windows.Graphics.Imaging.BitmapDecoder])
  $sb = Await ($dec.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
  $res = Await ($engine.RecognizeAsync($sb)) ([Windows.Media.Ocr.OcrResult])
  $ms.Dispose()
  $res
}
function Rows($res) {
  $words = @()
  foreach ($l in $res.Lines) { foreach ($wd in $l.Words) { $r = $wd.BoundingRect; $words += [pscustomobject]@{ T = $wd.Text; X = $r.X; R = $r.X + $r.Width; Top = $r.Y; Bot = $r.Y + $r.Height; Y = $r.Y + $r.Height / 2; H = $r.Height } } }
  $rows = @()
  foreach ($wd in ($words | Sort-Object Y)) {
    $hit = $null
    foreach ($r in $rows) { if ([math]::Abs($r.Y - $wd.Y) -lt [math]::Max(6, $wd.H * 0.6)) { $hit = $r; break } }
    if ($hit) { [void]$hit.W.Add($wd) } else { $rows += [pscustomobject]@{ Y = $wd.Y; W = [System.Collections.ArrayList]@($wd) } }
  }
  foreach ($r in $rows) {
    $ws = $r.W | Sort-Object X
    [pscustomobject]@{ Text = ($ws | ForEach-Object { $_.T }) -join ' '; X = ($ws | Measure-Object X -Minimum).Minimum; R = ($ws | Measure-Object R -Maximum).Maximum; Top = ($ws | Measure-Object Top -Minimum).Minimum; Bot = ($ws | Measure-Object Bot -Maximum).Maximum; Y = $r.Y }
  }
}
function Plain([string]$t) {
  $d = $t.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $d.ToCharArray()) { if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) } }
  $sb.ToString()
}
function Resized($src, [int]$sx, [int]$sy, [int]$sw, [int]$sh, [double]$f) {
  $b = New-Object System.Drawing.Bitmap ([int][math]::Max(1, $sw * $f)), ([int][math]::Max(1, $sh * $f))
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $b.Width, $b.Height), (New-Object System.Drawing.Rectangle $sx, $sy, $sw, $sh), [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $b
}
# "Extra! You just caught ..." = a bonus fish on top of the normal catch
function IsExtra([string]$t) {
  $pre = ($t -split '(?i)c\S{2,6}t\s+an?\s')[0]
  return ($pre -match '(?i)e\s?x\s?t\s?r|xtra')
}
function Scan($full) {
  $W = $full.Width; $H = $full.Height
  $f1 = [math]::Min(1.0, $maxDim / [math]::Max($W, $H))
  $s1 = if ($f1 -lt 1.0) { Resized $full 0 0 $W $H $f1 } else { $full }
  $rows1 = Rows (Recognize $s1)
  if ($f1 -lt 1.0) { $s1.Dispose() }
  $outl = @()
  foreach ($r in $rows1) {
    if ($r.Text -notmatch '(?i)c\S{2,6}t\s+an?\b|kg|\d%\)') { continue }
    $x0 = $r.X / $f1; $x1 = $r.R / $f1; $y0 = $r.Top / $f1; $y1 = $r.Bot / $f1
    $rh = [math]::Max(4, $y1 - $y0)
    $padX = $rh * 1.5; $padY = $rh * 0.45
    $cx = [int][math]::Max(0, $x0 - $padX); $cy = [int][math]::Max(0, $y0 - $padY)
    $cw = [int]([math]::Min($W, $x1 + $padX) - $cx); $ch = [int]([math]::Min($H, $y1 + $padY) - $cy)
    if ($cw -lt 8 -or $ch -lt 4) { continue }
    $reads = New-Object 'System.Collections.Generic.List[string]'
    $wts = New-Object 'System.Collections.Generic.List[double]'
    $reads.Add([FR]::Read((Plain $r.Text))); $wts.Add(0.5)
    $isEx = (IsExtra $r.Text)
    foreach ($th in @(36.0, 52.0, 76.0)) {
      $f2 = [math]::Min(3.5, [math]::Max(0.5, $th / $rh))
      $f2 = [math]::Min($f2, [math]::Min($maxDim / $cw, $maxDim / $ch))
      $crop = Resized $full $cx $cy $cw $ch $f2
      $rows2 = @(Rows (Recognize $crop))
      $crop.Dispose()
      foreach ($q in $rows2) { if ($q.Text -match '(?i)kg') { $reads.Add([FR]::Read((Plain $q.Text))); $wts.Add(1.0); if (IsExtra $q.Text) { $isEx = $true }; if ($ImgFile) { $outl += ('D|' + [int]($r.Y / $f1) + '|' + (Plain $q.Text)) } } }
    }
    if ($ImgFile) { $outl += ('D|' + [int]($r.Y / $f1) + '|' + (Plain $r.Text)) }
    $b = [FR]::Best($reads, $wts)
    if ($b) { $outl += ('L|' + [int]($r.Y / $f1) + '|' + $b + '|' + $(if ($isEx) { 'E' } else { 'N' })) }
  }
  $outl
}

LoadData
while ($true) {
  if (-not $ImgFile -and -not (Get-Process -Id $ParentPid -ErrorAction SilentlyContinue)) { break }
  if ($ImgFile -or (Test-Path $req)) {
    try {
      LoadData
      if ($ImgFile) {
        $full = [System.Drawing.Bitmap]::FromFile($ImgFile); $id = 'file'
      } else {
        $a = ((Get-Content $req -Raw).Trim()) -split ' '
        Remove-Item $req -Force
        $x = [int]$a[0]; $y = [int]$a[1]; $w = [int]$a[2]; $h = [int]$a[3]; $id = $a[4]
        $full = New-Object System.Drawing.Bitmap $w, $h
        $g = [System.Drawing.Graphics]::FromImage($full)
        $g.CopyFromScreen($x, $y, 0, 0, $full.Size)
        $g.Dispose()
      }
      $lines = @($id) + @(Scan $full)
      $full.Dispose()
      [IO.File]::WriteAllText($out + '.tmp', ($lines -join $nl), [Text.Encoding]::UTF8)
      Move-Item ($out + '.tmp') $out -Force
    } catch {
      [IO.File]::WriteAllText($out, 'ERR ' + $_.Exception.Message)
    }
    if ($Once) { break }
  }
  Start-Sleep -Milliseconds 25
}

)
return ws1 . "`r`n" . ws2
}

InfoMonGet(ByRef l, ByRef t, ByRef w, ByRef h) {
	global RobloxHwnd, GuiHwnd
	hw := (RobloxHwnd and WinExist("ahk_id " . RobloxHwnd)) ? RobloxHwnd : GuiHwnd
	hm := DllCall("MonitorFromWindow", "Ptr", hw, "UInt", 2, "Ptr")
	VarSetCapacity(mi, 40, 0)
	NumPut(40, mi, 0, "UInt")
	if (!hm or !DllCall("GetMonitorInfo", "Ptr", hm, "Ptr", &mi))
		{
		l := 0
		t := 0
		w := A_ScreenWidth
		h := A_ScreenHeight
		return
		}
	l := NumGet(mi, 4, "Int")
	t := NumGet(mi, 8, "Int")
	w := NumGet(mi, 12, "Int") - l
	h := NumGet(mi, 16, "Int") - t
}

InfoPanelPxW() {
	global DpiF, FishScanOn
	return Round((FishScanOn ? 300 : 246) * (DpiF ? DpiF : 1))
}

InfoPanelPxH() {
	global DpiF, FishScanOn
	return Round((FishScanOn ? 244 : 164) * (DpiF ? DpiF : 1))
}

InfoCursorGui(ByRef gx, ByRef gy) {
	global GuiHwnd, DpiF
	VarSetCapacity(pt, 8, 0)
	DllCall("GetCursorPos", "Ptr", &pt)
	DllCall("ScreenToClient", "Ptr", GuiHwnd, "Ptr", &pt)
	f := DpiF ? DpiF : 1
	gx := Round(NumGet(pt, 0, "Int") / f)
	gy := Round(NumGet(pt, 4, "Int") / f)
}

HomeSync:
if (!SectionBuilt.HasKey("Home"))
	return
GuiControl, 1:Choose, DashCast, % (CastMode = "Perfect") ? 2 : 1
GuiControl, 1:Choose, DashSmart, % SmartCast ? 2 : 1
GuiControl, 1:Choose, DashPassive, % PassiveAll ? 2 : 1
GuiControl, 1:Choose, DashHide, % HideOverlay ? 2 : 1
GuiControl, 1:Choose, DashInfo, % InfoPanelOn ? 2 : 1
GuiControl, 1:Choose, DashAdapt, % AdaptiveCast ? 2 : 1
GuiControl, 1:Choose, DashScan, % FishScanOn ? 2 : 1
GuiControl, 1:, DashAcMs, %AdaptiveCastMs%
return

DashAcMsChanged:
GuiControlGet, DashAcV, 1:, DashAcMs
; "-" alone (still typing) or other text is ignored until it is a whole number
if (!ErrorLevel and RegExMatch(DashAcV, "^\s*-?\d+\s*$"))
	{
	AdaptiveCastMs := Round(DashAcV + 0)
	if (AdaptiveCastMs < -250)
		AdaptiveCastMs := -250
	if (AdaptiveCastMs > 5000)
		AdaptiveCastMs := 5000
	}
gosub, QueueAutoSave
return

DashChanged:
GuiControlGet, DashV, 1:, %A_GuiControl%
if (ErrorLevel)
	return
DashOn := (DashV = "On")
if (A_GuiControl = "DashCast")
	{
	CastMode := DashV
	GuiControl, 1:ChooseString, CastMode, %DashV%
	gosub, ApplyCastModeLocks
	}
else if (A_GuiControl = "DashSmart")
	{
	SmartCast := DashOn
	GuiControl, 1:, SmartCast, % DashOn ? 1 : 0
	CastSeenN := 0
	CastMissN := 0
	}
else if (A_GuiControl = "DashPassive")
	{
	PassiveAll := DashOn
	GuiControl, 1:, PassiveAll, % DashOn ? 1 : 0
	}
else if (A_GuiControl = "DashHide")
	{
	HideOverlay := DashOn
	GuiControl, 1:, HideOverlay, % DashOn ? 1 : 0
	}
else if (A_GuiControl = "DashInfo")
	{
	InfoPanelOn := DashOn
	gosub, InfoPanelTick
	}
else if (A_GuiControl = "DashAdapt")
	AdaptiveCast := DashOn
else if (A_GuiControl = "DashScan")
	{
	if (DashOn and !FishScanOn)
		{
		MsgBox, 0x40034, DeepFish - Fish Scanner, The fish scanner and value calculator are NOT 100`% accurate.`n`nThey read the "You just caught a ..." message with text recognition, so now and then a name or weight can be misread or a message missed. Fish values, the session total and the extra-fish count are estimates.`n`nTurn the fish scanner on anyway?
		IfMsgBox, No
			{
			GuiControl, 1:Choose, DashScan, 1
			return
			}
		}
	FishScanOn := DashOn
	if (FishScanOn and !FileExist(A_ScriptDir . "\FischFishData.txt"))
		{
		ToolTip, Downloading the fish value list ...
		FsLoadData()
		ToolTip
		if (!FileExist(A_ScriptDir . "\FischFishData.txt"))
			MsgBox, 0x40030, DeepFish - Fish Scanner, Could not download the fish value list from Fischipedia right now. It will try again by itself while the macro runs.
		}
	; rebuild the info panel with (or without) the fish rows
	if (hInfoP)
		{
		Gui, InfoP:Destroy
		hInfoP := 0
		IpShown := false
		Loop 12
			IpLast%A_Index% := ""
		}
	gosub, InfoPanelTick
	}
gosub, QueueAutoSave
return

HomeCompute:
if (!MacroRunning)
	HmV1 := "Idle"
else if (KbBusy)
	HmV1 := "Keeperbound recharge"
else if (AqBusy)
	HmV1 := "Aquarium"
else if (MgInPlay)
	HmV1 := "Reeling"
else if (CastHolding)
	HmV1 := "Casting"
else if (PassiveAll or (SwPassive and SpecialRod = "Stellarwave Melody"))
	HmV1 := "Watching (passive)"
else
	HmV1 := "Waiting for a bite"
HmV2 := (MacroRunning and MgInPlay and WhiteBarSize != "") ? "Bar " . Round(WhiteBarSize) . " px" : "---"
HmV3 := !MacroRunning ? "---" : (GetKeyState("LButton") ? "Holding" : "Released")
HmV4 := (SpecialRod = "" or SpecialRod = "None") ? "Normal rod" : SpecialRod
HmV5 := CaughtTotal() . ((FishScanOn and FsExtraCount > 0) ? "  (+" . FsExtraCount . " extra)" : "")
if (WhStartTick and MacroRunning)
	{
	HmMs := A_TickCount - WhStartTick
	HmHr := HmMs / 3600000.0
	HmV6 := ((HmHr > 0.01) ? Round(CaughtTotal() / HmHr) : 0) . " / hr"
	HmMin := HmMs // 60000
	HmV7 := (HmMin // 60) . "h " . Mod(HmMin, 60) . "m"
	}
else
	{
	HmV6 := "---"
	HmV7 := "---"
	}
HmV8 := (KeeperAuto and KbOcrLast != "") ? KbOcrLast : "---"
HmV8 := StrReplace(HmV8, "power bar ", "")
return

HomeTick:
gosub, HomeCompute
for i, nm in ["HmPhase", "HmProg", "HmInput", "HmRod", "HmCaught", "HmRate", "HmSess", "HmPower"]
	{
	nv := HmV%i%
	if (HmLast%i% != nv)
		{
		HmLast%i% := nv
		GuiControl, 1:, %nm%, %nv%
		}
	}
return

;====================================================================================================;

BuildGeneralSection:

hC := AddPanel(CARDX, 120, CARDW, 152)
GeneralCtrls.Push(hC)
hC := AddPanel(CARDX, 282, CARDW, 168)
GeneralCtrls.Push(hC)
hC := AddPanel(CARDX, 460, CARDW, 308)
GeneralCtrls.Push(hC)

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y130 w%TXW% h16 HwndhL, HOTKEYS && WINDOW
GeneralCtrls.Push(hL)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 152

GeneralHotDefs := [ ["Start/Stop key","StartStopKeyCtrl",StartStopKey]
	, ["Reload key","ReloadKeyCtrl",ReloadKey]
	, ["Exit key","ExitKeyCtrl",ExitKey] ]
for i, d in GeneralHotDefs
	{
	lbl := d[1]
	var := d[2]
	val := d[3]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	GeneralCtrls.Push(hL)
	Gui, Add, Hotkey, x%IX% y%Y% w%IW% h20 v%var% HwndhC, %val%
	GeneralCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	Y += RH
	}

Gui, Font, s9 c%ColorText%, Segoe UI
aotChk := GuiAlwaysOnTop ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w230 h20 c%ColorText% vGuiAlwaysOnTop %aotChk% gToggleAlwaysOnTop HwndhC, Window always on top
GeneralCtrls.Push(hC)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%IX% y%Y% w%IW% h20 HwndhL, Theme (restarts the window):
GeneralCtrls.Push(hL)
Gui, Font, s9 c%ColorText%, Segoe UI
Y += 22
ThemeY := Y - 2
ThemeList := "Mono|Midnight|Violet|Emerald|Crimson|Classic"
ThemeIdx := {"Mono": 1, "Midnight": 2, "Violet": 3, "Emerald": 4, "Crimson": 5, "Classic": 6}[GuiTheme]
Gui, Add, DropDownList, x%IX% y%ThemeY% w%IW% h200 vGuiThemePick gGuiThemeChanged Choose%ThemeIdx% HwndhC, %ThemeList%
GeneralCtrls.Push(hC)
ThemedCtrls.Push(hC)
IconTips[hC] := "Colour theme for this window.`n`nMono - near-black, minimal (default)`nMidnight - dark blue-grey`nViolet, Emerald, Crimson - other accents`nClassic - the original all-blue look"

keepChk := GuiKeepOpen ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w230 h20 c%ColorText% vGuiKeepOpen %keepChk% gToggleKeepOpen HwndhC, Always open after pressing Start
GeneralCtrls.Push(hC)

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y292 w%TXW% h16 HwndhL, AUTOMATIC GAME SETUP
GeneralCtrls.Push(hL)
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%DX% y292 w%DW% h16 Center HwndhL, delay ms
GeneralCtrls.Push(hL)

Y := 314
GeneralBoolDefs := [ ["Auto-lower graphics","AutoLowerGraphics","AutoGraphicsDelay"]
                   , ["Auto-zoom camera","AutoZoomInCamera","AutoZoomDelay"]
                   , ["Auto-enable camera mode","AutoEnableCameraMode","AutoCameraDelay"]
                   , ["Auto-look down","AutoLookDownCamera","AutoLookDelay"]
                   , ["Auto-blur camera","AutoBlurCamera","AutoBlurDelay"] ]

Gui, Font, s9 c%ColorText%, Segoe UI
for i, d in GeneralBoolDefs
	{
	lbl := d[1]
	var := d[2]
	dvar := d[3]
	val := %var%
	chk := val ? "Checked" : ""
	Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% v%var% %chk% gQueueAutoSave HwndhC, %lbl%
	GeneralCtrls.Push(hC)
	EdOpt := TmNumOpt(dvar)
	Gui, Add, Edit, x%DX% y%Y% w%DW% h20 v%dvar% gQueueAutoSave HwndhD %EdOpt%, % %dvar%
	GeneralCtrls.Push(hD)
	ThemedCtrls.Push(hD)
	Y += RH
	}

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y470 w%TXW% h16 HwndhL, RECOVERY
GeneralCtrls.Push(hL)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 492
GeneralNumDefs := [ ["Restart delay (ms)","RestartDelay"], ["Re-equip after N failed casts","UnstickAfter"] ]
for i, d in GeneralNumDefs
	{
	lbl := d[1]
	var := d[2]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	GeneralCtrls.Push(hL)
	EdOpt := TmNumOpt(var)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %EdOpt%, % %var%
	GeneralCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	Y += RH
	}

GeneralKeyDefs := [ ["Rod hotbar slot key","RodSlotKey"
	, "The hotbar key your fishing rod sits on.`n`nUsed to un-equip and re-equip the rod when a`ncast gets stuck on the ground."]
	, ["Equipment bag key","BagSlotKey"
	, "The hotbar key for your equipment bag.`n`nIf set, the macro switches to this and back to`nthe rod to un-stick a cast. Leave blank to just`npress the rod key twice instead."] ]

for i, d in GeneralKeyDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	GeneralCtrls.Push(hL)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC, % %var%
	GeneralCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	GeneralCtrls.Push(hQ)
	IconTips[hQ] := hint
	Y += RH
	}

Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Timing offset (ms):
GeneralCtrls.Push(hL)
Gui, Add, Edit, x%IX% y%Y% w%IW% h20 vTimeOffset gTimeOffsetChanged HwndhC, %TimeOffset%
GeneralCtrls.Push(hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
GeneralCtrls.Push(hQ)
IconTips[hQ] := "Shifts EVERY wait in the macro by this many ms.`n0 is normal.`n`nNegative is faster: -50 makes every wait 50ms`nshorter (a wait never goes below 0). Positive is`nslower and safer if the game misses inputs.`n`nCovers menus, camera setup, casting waits,`nrecharge, aquarium, totem and sign clicks.`nBar control and cast power timings are left alone`nso reeling and casting still work."
Y += RH
Gui, Font, s9 c%ColorText%, Segoe UI
AuChk := AutoUpdate ? "Checked" : ""
AuLbl := "Auto update" . ((DFModBuild > 0) ? "   (v" . DFVersion . ")" : "")
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vAutoUpdate %AuChk% gAutoUpdateChanged HwndhC, %AuLbl%
GeneralCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
GeneralCtrls.Push(hQ)
IconTips[hQ] := "ON - when a new build is published, DeepFish`ndownloads it and restarts on it by itself. It checks`nwhen it starts and every 10 minutes, but never`nwhile the macro is fishing. Your old file is kept`nnext to it as .bak.`n`nOFF (default) - never updates by itself."
Y += RH
Gui, Font, s9 c%ColorText%, Segoe UI
AdvChk := AdvancedOn ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vAdvancedOn %AdvChk% gAdvancedOnChanged HwndhC, Advanced settings
GeneralCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
AdvBtnY := Y - 2
Gui, Add, Text, x562 y%AdvBtnY% w96 h24 Center +0x100 +0x200 gAdvOpen HwndhC, Open
GeneralCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 96, 24, 6)
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
GeneralCtrls.Push(hQ)
IconTips[hQ] := "ON - every timer in the macro can be tuned on the`nAdvanced page (Open): failsafes, every pause in`ncasting, the minigame, Stellarwave, Keeperbound,`nAquarium and Totem.`n`nOFF - the built-in defaults are used. Your custom`nvalues are kept for when you turn it back on."
Y += RH
Gui, Font, s9 c%ColorText%, Segoe UI
HoChk := HideOverlay ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vHideOverlay %HoChk% gOverlayOptChanged HwndhC, Hide overlay while running
GeneralCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
GeneralCtrls.Push(hQ)
IconTips[hQ] := "ON - while the macro runs (any rod, any mode), the`ninfo text and the bar overlay are invisible. The`nmacro still works exactly the same.`n`nStop the macro to see them again."
Y += RH
Gui, Font, s9 c%ColorText%, Segoe UI
PaChk := PassiveAll ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vPassiveAll %PaChk% gPassiveAllChanged HwndhC, Passive mode (every rod)
GeneralCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
GeneralCtrls.Push(hQ)
IconTips[hQ] := "ON - the macro does NOT cast or shake, for ANY rod.`nAfter you press Start it just watches your screen`nand plays the minigame whenever it shows up, then`ngoes back to watching. You cast and shake yourself.`n`nKeeperbound recharge, totems and aquarium still run`nbetween fish.`n`nOFF - normal: the macro casts and shakes too."
Y += RH
Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Passive scan every (ms):
GeneralCtrls.Push(hL)
Gui, Add, Edit, x%IX% y%Y% w%IW% h20 vPassiveMs gPassiveAllChanged HwndhC +Number, %PassiveMs%
GeneralCtrls.Push(hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
GeneralCtrls.Push(hQ)
IconTips[hQ] := "How often passive mode looks for the minigame.`nLower = it starts playing sooner, but uses a bit`nmore CPU. 500 is a good default; 100-200 if you`nwant it to grab the minigame faster."
Y += RH

return

PassiveAllChanged:
GuiControlGet, PaV, 1:, PassiveAll
if (!ErrorLevel)
	PassiveAll := PaV ? true : false
GuiControlGet, PaMsV, 1:, PassiveMs
if (!ErrorLevel and PaMsV != "")
	PassiveMs := PaMsV + 0
gosub, QueueAutoSave
return

GuiThemeChanged:
GuiControlGet, GtV, 1:, GuiThemePick
if (ErrorLevel or GtV = "" or GtV = GuiTheme)
	return
IniWrite, %GtV%, %SettingsFile%, GUI, Theme
if (MacroRunning)
	{
	MsgBox, 4160, DeepFish, Theme saved. It applies the next time the macro starts (it is running right now).
	return
	}
gosub, SaveSettings
Reload
return

AutoUpdateChanged:
GuiControlGet, AuV, 1:, AutoUpdate
if (!ErrorLevel)
	AutoUpdate := AuV ? true : false
gosub, QueueAutoSave
if (AutoUpdate)
	SetTimer, DFCheckForUpdate, -500
return

TimeOffsetChanged:
GuiControlGet, TimeOffV, 1:, TimeOffset
if (!ErrorLevel)
	{
	TimeOffV := Trim(TimeOffV)
	if TimeOffV is number
		TimeOffset := TimeOffV + 0
	else if (TimeOffV = "" or TimeOffV = "-")
		TimeOffset := 0
	}
gosub, QueueAutoSave
return

;====================================================================================================;

BuildCastSection:

hC := AddPanel(CARDX, 120, CARDW, 62)
CastCtrls.Push(hC)

Gui, Font, s9 c%ColorMuted%, Segoe UI
Y := ContentTop

Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Cast mode:
CastCtrls.Push(hL)
CastModeChoice := (CastMode = "Perfect") ? 2 : 1
Gui, Add, DropDownList, x%IX% y%Y% w%IW% h100 vCastMode gCastModeChanged Choose%CastModeChoice% HwndhC, Normal|Perfect
CastCtrls.Push(hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
CastCtrls.Push(hQ)
IconTips[hQ] := "How the rod is cast.`n`nNORMAL - holds the mouse for a fixed time,`nthen lets go. Simple and reliable.`n`nPERFECT - watches the cast power bar and`nlets go the instant it fills, for a perfect`ncast every time. Needs the green and white`nbar colors to match your game."

CastGroupTop := 202

; ---- Normal group ----
hC := AddPanel(CARDX, 192, CARDW, 104)
NormalCastCtrls.Push(hC)
hC := AddPanel(CARDX, 306, CARDW, 108)
NormalCastCtrls.Push(hC)

Y := CastGroupTop
NormalCastDefs := [ ["Hold rod cast duration (ms)","HoldRodCastDuration"
	, "How long the mouse is held down to cast.`n`nHIGHER = casts further out.`nLOWER  = casts closer in."]
	, ["Wait for bobber delay (ms)","WaitForBobberDelay"
	, "How long to wait after casting before it`nstarts looking for the shake button.`n`nRaise it if shaking starts before the`nbobber has landed."] ]
for i, d in NormalCastDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	NormalCastCtrls.Push(hL)
	EdOpt := TmNumOpt(var)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %EdOpt%, % %var%
	NormalCastCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	NormalCastCtrls.Push(hQ)
	IconTips[hQ] := hint
	Y += RH
	}
SmartCastChk := SmartCast ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w150 h20 c%ColorText% vSmartCast %SmartCastChk% gSmartCastChanged HwndhC, Smart cast, casts:
NormalCastCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
ScnX := CX + 152
Gui, Add, Edit, x%ScnX% y%Y% w40 h20 vSmartCastN gQueueAutoSave Number Limit2 HwndhC, %SmartCastN%
NormalCastCtrls.Push(hC)
IconTips[hC] := "How many casts in a row (1-10).`nEach cast holds for the Cast hold time, then it`nwaits Cast hold + 50 ms before the next one."
ScnX := CX + 198
Gui, Add, Text, x%ScnX% y%Y% w100 h20 +0x200 HwndhC, in a row
NormalCastCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
NormalCastCtrls.Push(hQ)
IconTips[hQ] := "ON - while the mouse is held it watches for the`ncast power bar. Once it has seen the bar on a few`ncasts, a cast with NO power bar is treated as a`nclick the game ignored (rod not out yet, catch`nanimation) and it recasts straight away instead`nof waiting for the bar failsafe. The 2nd miss in a`nrow also re-equips the rod.`n`nIf your game's power bar is never spotted it`nnever kicks in, so it cannot make casting worse.`n`nThe box: casts that many times in a row - each`ncast holds for Cast hold, then waits Cast hold +`n50 ms before the next. 2 is a double cast.`n`nOFF - plain timed cast."

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y316 w%TXW% h16 HwndhNCTipHdr, QUICK RULES — NORMAL
NormalCastCtrls.Push(hNCTipHdr)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
NormalCastTips := "• Casts a fixed distance every time.`n"
NormalCastTips .= "• Raise the hold duration to cast further out.`n"
NormalCastTips .= "• Raise the bobber delay on laggy servers.`n"
NormalCastTips .= "• No colors to calibrate — this always works."
Gui, Add, Text, x%CX% y338 w%TXW% h68 cFFFFFF HwndhNCTips, %NormalCastTips%
NormalCastCtrls.Push(hNCTips)
SpecialBrushes[hNCTips] := {brush: hBrushCard, text: 0xFFFFFF}

; ---- Perfect group ----
hC := AddPanel(CARDX, 192, CARDW, 222)
PerfectCastCtrls.Push(hC)
hC := AddPanel(CARDX, 424, CARDW, 148)
PerfectCastCtrls.Push(hC)

Gui, Font, s9 c%ColorMuted%, Segoe UI
Y := CastGroupTop
PerfectCastDefs := [ ["Green tolerance","PerfectGreenTolerance",1
	, "How closely the green marker on the cast bar`nmust match.`n`nHIGHER = more forgiving.`nTOO HIGH = matches the wrong thing."]
	, ["White tolerance","PerfectWhiteTolerance",1
	, "How closely the white fill bar must match.`n`nHIGHER = more forgiving.`nTOO HIGH = matches other white UI."]
	, ["Fail timeout (s)","PerfectFailTimeout",1
	, "How long to wait for a perfect release before`ngiving up and letting go anyway.`n`nStops the macro hanging if the bar is`nnever found."]
	, ["Release timing","PerfectReleaseTiming",0
	, "Nudges when it lets go.`n`nNEGATIVE = release EARLIER (use if it`nreleases too late).`nPOSITIVE = release LATER (use if it`nreleases too early).`n`n0 = default. Try steps of 0.5."]
	, ["Wait swings","PerfectWaitCycles",1
	, "How many full up-and-down swings of the`nwhite bar to watch before releasing.`n`n1 = watch one swing first (steadier timing,`nabout 0.8 s slower per cast).`n0 = release on the first swing."] ]
for i, d in PerfectCastDefs
	{
	lbl := d[1]
	var := d[2]
	isInt := d[3]
	hint := d[4]
	opt := isInt ? "+Number" : ""
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	PerfectCastCtrls.Push(hL)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %opt%, % %var%
	PerfectCastCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	PerfectCastCtrls.Push(hQ)
	IconTips[hQ] := hint
	Y += RH
	}

Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Green bar color:
PerfectCastCtrls.Push(hL)
Gui, Add, Edit, x%IX% y%Y% w%IW% h20 vPerfectGreenColor gColorFieldChanged HwndhC, % PerfectGreenColor
PerfectCastCtrls.Push(hC)
ThemedCtrls.Push(hC)
Gui, Add, Progress, x%SWX% y%Y% w%SWW% h20 vCastGreenSwatch HwndhCastGreenSwatch Background60AA4A, 0
PerfectCastCtrls.Push(hCastGreenSwatch)
Y += RH

Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, White bar color:
PerfectCastCtrls.Push(hL)
Gui, Add, Edit, x%IX% y%Y% w%IW% h20 vPerfectWhiteColor gColorFieldChanged HwndhC, % PerfectWhiteColor
PerfectCastCtrls.Push(hC)
ThemedCtrls.Push(hC)
Gui, Add, Progress, x%SWX% y%Y% w%SWW% h20 vCastWhiteSwatch HwndhCastWhiteSwatch BackgroundFFFEF3, 0
PerfectCastCtrls.Push(hCastWhiteSwatch)
Y += RH + 2

Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w200 h26 Center +0x100 +0x200 gOpenColorManager HwndhC, 🎨  Color Manager  (F9)
PerfectCastCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 200, 26, 7)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y434 w%TXW% h16 HwndhPCTipHdr, QUICK RULES — PERFECT
PerfectCastCtrls.Push(hPCTipHdr)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
PerfectCastTips := "• Releases too late? Lower Release timing by 0.5.`n"
PerfectCastTips .= "• Releases too early? Raise it by 0.5.`n"
PerfectCastTips .= "• Never releases at all? Re-pick the green and white`n"
PerfectCastTips .= "   colors in the Color Manager, or raise the tolerances.`n"
PerfectCastTips .= "• Falls back to a normal cast if the bar is never found,`n"
PerfectCastTips .= "   so a bad calibration cannot hang it."
Gui, Add, Text, x%CX% y456 w%TXW% h100 cFFFFFF HwndhPCTips, %PerfectCastTips%
PerfectCastCtrls.Push(hPCTips)
SpecialBrushes[hPCTips] := {brush: hBrushCard, text: 0xFFFFFF}

return

;====================================================================================================;

SmartCastChanged:
GuiControlGet, SmartCastV, 1:, SmartCast
if (!ErrorLevel)
	SmartCast := SmartCastV ? true : false
CastSeenN := 0
CastMissN := 0
gosub, QueueAutoSave
return

CastModeChanged:
GuiControlGet, CastMode, , CastMode
gosub, ApplyCastModeLocks
TargetSection := "Cast"
gosub, ShowSection
gosub, QueueAutoSave
return

;====================================================================================================;

ApplyCastModeLocks:
if (CastMode = "Perfect")
	{
	AutoZoomInCamera := false
	GuiControl, 1:, AutoZoomInCamera, 0
	GuiControl, 1:Disable, AutoZoomInCamera
	GuiControl, 1:Disable, AutoZoomDelay
	}
else
	{
	GuiControl, 1:Enable, AutoZoomInCamera
	GuiControl, 1:Enable, AutoZoomDelay
	}
return

;====================================================================================================;

BuildShakeSection:

hC := AddPanel(CARDX, 120, CARDW, 88)
ShakeCtrls.Push(hC)
hC := AddPanel(CARDX, 218, CARDW, 192)
ShakeCtrls.Push(hC)

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y130 w%TXW% h16 HwndhL, MODE
ShakeCtrls.Push(hL)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 152
Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Shake mode:
ShakeCtrls.Push(hL)
ShakeModeChoice := (ShakeMode = "Disabled") ? 2 : 1
Gui, Add, DropDownList, x%IX% y%Y% w%IW% h100 vShakeMode Choose%ShakeModeChoice% HwndhC, Navigation|Disabled
ShakeCtrls.Push(hC)
ThemedCtrls.Push(hC)
Y += RH

Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, In-game navigation key:
ShakeCtrls.Push(hL)
Gui, Add, Edit, x%IX% y%Y% w%IW% h20 vNavigationKey HwndhC, %NavigationKey%
ShakeCtrls.Push(hC)
ThemedCtrls.Push(hC)

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y228 w%TXW% h16 HwndhL, SEARCH AREA
ShakeCtrls.Push(hL)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 250
ShakeAreaDefs := [ ["Navigation failsafe (s)","NavigationShakeFailsafe"]
                 , ["Navigation spam delay (ms)","NavigationSpamDelay"]
                 , ["Search area left (%)","ShakeAreaLeftPct"]
                 , ["Search area right (%)","ShakeAreaRightPct"]
                 , ["Search area top (%)","ShakeAreaTopPct"]
                 , ["Search area bottom (%)","ShakeAreaBottomPct"] ]
for i, d in ShakeAreaDefs
	{
	lbl := d[1]
	var := d[2]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	ShakeCtrls.Push(hL)
	EdOpt := TmNumOpt(var)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %EdOpt%, % %var%
	ShakeCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	Y += RH
	}

return

;====================================================================================================;
;====================================================================================================;

BuildMinigameSection:


MgBlocks := {}

; ------------------------------------------------- detection mode, special rod, edge fallback
MgBlockOpen("mode", 120, 90)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y130 w%TXW% h16 HwndhL, DETECTION
MgAdd("mode", hL)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 152
Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Detection mode:
MgAdd("mode", hL)
ControlModeChoice := (ControlMode = "Manual") ? 1 : ((ControlMode = "Lines") ? 3 : 2)
Gui, Add, DropDownList, x%IX% y%Y% w%IW% h100 vControlMode gControlModeChanged Choose%ControlModeChoice% HwndhC, Manual|Precision|Lines
ControlModeDdl := hC
MgAdd("mode", hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("mode", hQ)
IconTips[hQ] := "How the macro steers the bar.`n`nPRECISION - looks at the bar every frame and`nre-decides instantly. It also tracks how fast`nthe fish is MOVING, so it aims where the fish`nis going. Almost no tuning needed.`n`nLINES - reads the bar's EDGES instead of`nmatching colors, so your color picks do not`nmatter at all.`n`nMANUAL - presses the mouse for a calculated`nnumber of milliseconds, then brakes. You tune`nthe timings yourself with multipliers."

Y += RH
Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Special rod (use default skin):
MgAdd("mode", hL)
SpecialBrushes[hL] := {brush: hBrushCard, text: ColorRedBGR}
SpecialRodChoice := (SpecialRod = "Pinions Aria") ? 2 : ((SpecialRod = "Requiem") ? 3 : ((SpecialRod = "Darkheart") ? 4 : ((SpecialRod = "Bellona's Waraxe") ? 5 : ((SpecialRod = "Dreambreaker") ? 6 : ((SpecialRod = "Tranquility") ? 7 : ((SpecialRod = "Noiseform") ? 8 : ((SpecialRod = "Verdant Oath") ? 9 : ((SpecialRod = "Lullaby") ? 10 : ((SpecialRod = "Castbound") ? 11 : ((SpecialRod = "Remembrance") ? 12 : ((SpecialRod = "MiguRod") ? 13 : ((SpecialRod = "Halibut Harpoon") ? 14 : ((SpecialRod = "Splitbranch Twig") ? 15 : ((SpecialRod = "Tryhard Rod") ? 16 : ((SpecialRod = "Stellarwave Melody") ? 17 : 1)))))))))))))))
Gui, Add, DropDownList, x%IX% y%Y% w%IW% h320 vSpecialRod gSpecialRodChanged Choose%SpecialRodChoice% HwndhC, None|Pinions Aria|Requiem|Darkheart|Bellona's Waraxe|Dreambreaker|Tranquility|Noiseform|Verdant Oath|Lullaby|Castbound|Remembrance|MiguRod|Halibut Harpoon|Splitbranch Twig|Tryhard Rod|Stellarwave Melody
MgAdd("mode", hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("mode", hQ)
IconTips[hQ] := "Extra behaviour for rods with their own`nmechanics.`n`nUse the DEFAULT rod skin. Other skins`nchange how the bar looks and break detection.`n`nSPLITBRANCH TWIG - clicks one of the two fish`nwhen the rod asks you to choose. The minigame`nitself is unchanged.`n`nSTELLARWAVE MELODY - clicks the zodiac signs on`nthe bar in the order shown above it, then reels`nas normal. Keep the cursor free (no shift lock`nor first person)."

; -------------------------------------------------------------------------------- bar colors
MgBlockOpen("colors", 204, 276)
Y := 220
ColorFieldDefs := [ ["Fish line color","FishColor","FishColorSwatch"
	, "The thin marker that slides along the bar."]
	, ["Bar left-end color","BarLeftColor","BarLeftColorSwatch"
	, "The LEFT end of the reeling bar.`n`nEach entry holds a LIST - if the bar changes`nshade as it fills, add every shade its left`nend takes."]
	, ["Bar right-end color","BarRightColor","BarRightColorSwatch"
	, "The RIGHT end of the reeling bar.`n`nEach entry holds a LIST - if the bar changes`nshade as it fills, add every shade its right`nend takes."]
	, ["Bar arrow color","ArrowColor","ArrowColorSwatch"
	, "The small arrow drawn inside the reeling bar."] ]

for i, d in ColorFieldDefs
	{
	lbl := d[1]
	var := d[2]
	sw := d[3]
	hint := d[4]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	MgAdd("colors", hL)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gColorFieldChanged HwndhC, % %var%
	MgAdd("colors", hC)
	ThemedCtrls.Push(hC)
	swVal := Format("{:06X}", ColMain(%var%))
	if (!ColCount(%var%))
		swVal := "202020"
	Gui, Add, Progress, x%SWX% y%Y% w%SWW% h20 v%sw% Background%swVal% HwndhS, 0
	MgAdd("colors", hS)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	MgAdd("colors", hQ)
	IconTips[hQ] := hint
	Y += RH
	}

MiniColorFieldDefs := [ ["Bar color tolerance","BarColorTolerance"
	, "How closely the picked colors must match.`n`nHIGHER = more forgiving.`nTOO HIGH = matches the wrong thing.`n`nBefore pushing this up, add the extra shade`nas another color in the Color Manager - that`nis far safer than a wide tolerance."]
	, ["Fish line tolerance","FishBarColorTolerance"
	, "How closely a pixel must match the fish line`ncolor to count as the fish.`n`nHIGHER = more forgiving. Raise this if the`nminigame is never detected.`nTOO HIGH = scenery gets mistaken for the fish."]
	, ["Arrow tolerance","ArrowColorTolerance"
	, "How closely the arrow's color must match.`n`nHIGHER = more forgiving (good if the rod`nshifts hue or the screen shakes).`nTOO HIGH = matches the wrong thing."] ]

for i, d in MiniColorFieldDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	MgAdd("colors", hL)
	EdOpt := TmNumOpt(var)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %EdOpt%, % %var%
	MgAdd("colors", hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	MgAdd("colors", hQ)
	IconTips[hQ] := hint
	Y += RH
	}

Y += 4
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w200 h26 Center +0x100 +0x200 gOpenColorManager HwndhC, 🎨  Color Manager  (F9)
MgAdd("colors", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 200, 26, 7)
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x412 y%Y% w316 h26 +0x200 HwndhL, Every entry holds a LIST — add each shade.
MgAdd("colors", hL)
SpecialBrushes[hL] := {brush: hBrushCard, text: ColorMutedBGR}

Y += 30
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w200 h26 Center +0x100 +0x200 gMgRestoreDefaults HwndhC, ↺  Restore defaults
MgAdd("colors", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 200, 26, 7)
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x412 y%Y% w316 h26 +0x200 HwndhL, Resets Setup and every Color Manager color.
MgAdd("colors", hL)
SpecialBrushes[hL] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

; --------------------------------------------------------------------- falling notes (Pinions)
MgBlockOpen("notes", 204, 162)
Y := 220
Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Note color:
MgAdd("notes", hL)
SpecialBrushes[hL] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Add, Edit, x%IX% y%Y% w%IW% h20 vNoteColor gColorFieldChanged HwndhC, % NoteColor
MgAdd("notes", hC)
ThemedCtrls.Push(hC)
swVal := Format("{:06X}", ColMain(NoteColor))
if (!ColCount(NoteColor))
	swVal := "202020"
Gui, Add, Progress, x%SWX% y%Y% w%SWW% h20 vNoteColorSwatch Background%swVal% HwndhS, 0
MgAdd("notes", hS)
Y += RH

NoteFieldDefs := [ ["Note tolerance","NoteColorTolerance"
	, "Leave at 15.`n`nPink note line missing while notes fall:`nraise to 18-22.`n`nFish icon getting marked as a note:`nlower to 10-12.`n`nCapped at 25."]
	, ["Note priority","NoteBias"
	, "Leave at 100.`n`nPinions Aria: losing fish while the bar is away`non a note: lower to 80 (keeps 22 % progress in`nhand before leaving) or 60 (keeps 32 %).`n0 = ignore notes.`n`nThe bar only leaves the fish for a note when`nthe progress can afford it. Notes it can catch`nwithout leaving the fish are always taken.`n`nOther rods: 100 = go straight to the note,`n0 = track the fish only."]
	, ["Resonance hand-off (px)","NoteHandoff"
	, "Resonance state only.`n`nHow many pixels BEFORE a note lands to start`nmoving to the next note behind it.`n`nHIGHER = leaves early, reaches the second note`nin time but can drop the first.`n0 = never leave early (old behaviour)."] ]

for i, d in NoteFieldDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	MgAdd("notes", hL)
	SpecialBrushes[hL] := {brush: hBrushCard, text: ColorYellowBGR}
	EdOpt := TmNumOpt(var)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %EdOpt%, % %var%
	MgAdd("notes", hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	MgAdd("notes", hQ)
	IconTips[hQ] := hint
	Y += RH
	}

Y += 4
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w200 h26 Center +0x100 +0x200 gOpenColorManager HwndhC, 🎨  Color Manager  (F9)
MgAdd("notes", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 200, 26, 7)
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x412 y%Y% w316 h26 +0x200 HwndhL, Notes are hunted across the Shake search area.
MgAdd("notes", hL)
SpecialBrushes[hL] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

; -------------------------------------------------- extra colors (Tryhard Rod, Castbound)
RodColTip := "Leave empty if this rod already works for you.`n`nOnly for screens where the rod's own detection`nnever picks this up: open the Color Manager,`nPick from screen, and click it in game.`n`nThe rod's own detection still runs - these`nare added to it. Empty = nothing changes."
RodTolTip := "How closely a pixel must match one of the`nextra colors above. Leave at the default.`n`nHIGHER = more forgiving.`nTOO HIGH = scenery gets mistaken for it."
; the Stellarwave color boxes hold the picked preset's colours; the other preset's are kept aside.
; Settings from before this saved the zodiac colours there even with Ominous Ouija picked - move them aside once
SwColsNormalDef := "0x55446D|26|0xAFDAE8|22|0xFFFFFF|30"
SwColsOuijaDef := "0x959088|14|0xD4C5A4|40|0xE8E1C5|30"
SwPresetCur := SwPreset
if (SwPreset = "Ominous Ouija" and SwColsOuija = "" and (SwColsNormal = "" or InStr(SwColsNormal, "0x959088") = 1))
	{
	; once only (the ouija set is stored from then on); an earlier build put the ouija colours in the zodiac slot
	if (SwColsNormal = "" and InStr(SwColsGet(), "0x959088") != 1)
		SwColsNormal := SwColsGet()
	else
		SwColsNormal := SwColsNormalDef
	if (InStr(SwColsGet(), "0x959088") != 1)
		SwColsSet(SwColsOuijaDef)
	SwColsOuija := SwColsGet()
	}
SwColTip := "Filled in with the rod's own color. Change it`nonly if this part is not picked up on your`nscreen: open the Color Manager, Pick from`nscreen, and click it in game.`n`nEmpty the box to go back to the normal color."
SwTolTip := "How closely a pixel must match the colors`nabove. Leave at the default.`n`nHIGHER = more forgiving.`nTOO HIGH = scenery gets mistaken for it."
RodColBlockDefs := [ ["trycol", [ ["Extra bar colors","TryhardBarColors","c","Click the bar while the fish is inside it`n(bright red) AND while it is outside (dark red).","e.g. 0x9E0406, 0x37080C"]
		, ["Bar tolerance","TryhardBarTol","t",""]
		, ["Extra fish colors","TryhardFishColors","c","Click the dark marker that sticks out`nabove the bar.","e.g. 0x30070C"]
		, ["Fish tolerance","TryhardFishTol","t",""]
		, ["Extra track colors","TryhardTrackColors","c","Only if the bar is still not found with its`ncolors picked: click the dark red track`njust beside the bar.","e.g. 0x1F121A"]
		, ["Track tolerance","TryhardTrackTol","t",""] ], "EXTRA COLORS  -  ONLY IF THE BAR OR FISH IS NOT PICKED UP" ]
	, ["cbcol", [ ["Extra track colors","CastboundTrackColors","c","Pick this first. Click the purple track the bar`nslides on - add a click where it runs over`nbright scenery too."]
		, ["Track tolerance","CastboundTrackTol","t",""]
		, ["Extra sword colors","CastboundFishColors","c","0x5522A3 is the normal sword color and changes`nnothing on its own. Add your own picks after it:`nclick the purple sword marker the bar chases."]
		, ["Sword tolerance","CastboundFishTol","t",""]
		, ["Extra bar colors","CastboundBarColors","c","Only helps if the bar looks very dark on your`nscreen. Click the bar."]
		, ["Bar tolerance","CastboundBarTol","t",""] ], "EXTRA COLORS  -  ONLY IF THE BAR OR SWORD IS NOT PICKED UP" ]
	, ["swcol", [ ["Bar color","StellarBarColors","c","The thin dark purple frame around the bar`n(not the colorful inside). 0x55446D is the`nnormal color.`n`nOminous Ouija: the thin grey rims along`nthe bar, 0x959088.","default 0x55446D"]
		, ["Bar tolerance","StellarBarTol","t",""]
		, ["Fish color","StellarFishColors","c","The light blue line of the fish on the bar.`n0xAFDAE8 is the normal color.`n`nOminous Ouija: the planchette, 0xD4C5A4.","default 0xAFDAE8"]
		, ["Fish tolerance","StellarFishTol","t",""]
		, ["Fish head color","StellarHeadColors","c","The white note head of the fish, just above`nthe bar. 0xFFFFFF is the normal color.`n`nOminous Ouija: the light edge of the`nplanchette, 0xE8E1C5.","default 0xFFFFFF"]
		, ["Fish head tolerance","StellarHeadTol","t",""] ], "STELLARWAVE COLORS  -  ONLY IF THE BAR OR FISH IS NOT PICKED UP"
		, "Filled in with the Preset's own colors - they switch with it. Empty a box for its normal color.", SwColTip, SwTolTip ] ]
for RcI, RcD in RodColBlockDefs
	{
	RcName := RcD[1]
	RcRows := RcD[2]
	RcHead := RcD[3]
	MgBlockOpen(RcName, 204, 94 + RcRows.MaxIndex() * RH)
	Y := 218
	Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
	Gui, Add, Text, x%CX% y%Y% w520 h16 HwndhL, %RcHead%
	MgAdd(RcName, hL)
	Y += 18
	Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
	RcSub := (RcD.Length() >= 4) ? RcD[4] : "Empty = the rod's own detection, exactly as before. These are added on top of it."
	Gui, Add, Text, x%CX% y%Y% w520 h16 HwndhL, %RcSub%
	MgAdd(RcName, hL)
	SpecialBrushes[hL] := {brush: hBrushCard, text: ColorMutedBGR}
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	Y += 22
	for RcJ, d in RcRows
		{
		lbl := d[1]
		var := d[2]
		Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
		MgAdd(RcName, hL)
		SpecialBrushes[hL] := {brush: hBrushCard, text: ColorYellowBGR}
		if (d[3] = "c")
			{
			Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gColorFieldChanged HwndhC, % %var%
			MgAdd(RcName, hC)
			ThemedCtrls.Push(hC)
			if (d.Length() >= 5 and d[5] != "")
				DllCall("SendMessage", "Ptr", hC, "UInt", 0x1501, "Ptr", 1, "WStr", d[5])
			swVal := Format("{:06X}", ColMain(%var%))
			if (!ColCount(%var%))
				swVal := "202020"
			Gui, Add, Progress, x%SWX% y%Y% w%SWW% h20 v%var%Swatch Background%swVal% HwndhS, 0
			MgAdd(RcName, hS)
			RcTip := d[4] . "`n`n" . ((RcD.Length() >= 5) ? RcD[5] : RodColTip)
			}
		else
			{
			EdOpt := TmNumOpt(var)
			Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %EdOpt%, % %var%
			MgAdd(RcName, hC)
			ThemedCtrls.Push(hC)
			RcTip := (RcD.Length() >= 6) ? RcD[6] : RodTolTip
			}
		Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
		Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
		Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
		MgAdd(RcName, hQ)
		IconTips[hQ] := RcTip
		Y += RH
		}
	Y += 4
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%CX% y%Y% w200 h26 Center +0x100 +0x200 gOpenColorManager HwndhC, 🎨  Color Manager  (F9)
	MgAdd(RcName, hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
	RoundCtrl(hC, 200, 26, 7)
	Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
	Gui, Add, Text, x412 y%Y% w316 h26 +0x200 HwndhL, Pick from screen, then click that part in game.
	MgAdd(RcName, hL)
	SpecialBrushes[hL] := {brush: hBrushCard, text: ColorMutedBGR}
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	}

; ------------------------------------------------------------------- Halibut Harpoon
MgBlockOpen("halicol", 204, 50)
Y := 219
HaliChk := HalibutPlayMinigame ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vHalibutPlayMinigame %HaliChk% gHalibutPlayChanged HwndhC, Play minigame
MgAdd("halicol", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("halicol", hQ)
IconTips[hQ] := "ON - the bar goes for the exclamation mark`nwhen it appears (the harpoon minigame).`n`nOFF - the bar stays on the fish line the whole`ntime and ignores the exclamation mark."

; ------------------------------------------------------------------- Stellarwave Melody
MgBlockOpen("stellar", 204, 284)
Y := 219
SwChk := SwClickSigns ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vSwClickSigns %SwChk% gSwClickChanged HwndhC, Click the signs
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - clicks the zodiac signs on the bar in the`norder shown above it, while it keeps reeling.`n`nOFF - only reels. Turn it off if the clicks make`nyour fights worse."
Y += RH
SwFastChk := SwFastClicks ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vSwFastClicks %SwFastChk% gSwFastChanged HwndhC, Fast sign clicks
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - clicks each sign as soon as it appears,`nwith a shorter click, so the signs go faster.`n`nOFF - waits until each sign is fully drawn`nbefore clicking. Slower, the careful way.`n`nTurn it off if signs get missed or the wrong`nsign gets clicked."
Y += RH
SwAllChk := SwAllSigns ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w150 h20 c%ColorText% vSwAllSigns %SwAllChk% gSwAllSignsChanged HwndhC, Wait for signs:
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
SwWnX := CX + 152
Gui, Add, Edit, x%SwWnX% y%Y% w40 h20 vSwWaitN gQueueAutoSave Number Limit2 HwndhC, %SwWaitN%
MgAdd("stellar", hC)
IconTips[hC] := "How many signs to wait for before clicking (1-12).`n12 = all of the signs for this round."
SwWnX := CX + 198
Gui, Add, Text, x%SwWnX% y%Y% w100 h20 +0x200 HwndhC, then click
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - waits until the number of signs in the box`n(12 = every sign for this round) is on the bar,`nthen clicks them in order with the normal`n(1.1.7) clicks. With Max sign speed on, they go out`nin one burst instead.`n`nOFF - clicks each sign as it comes in."
Y += RH
SwFirstChk := SwSignsFirst ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vSwSignsFirst %SwFirstChk% gSwSignsFirstChanged HwndhC, Signs before bar
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - clicking the signs comes first. While a sign`nis waiting to be clicked the macro stops reeling,`nand it clicks even when the fish is off the bar.`nReeling carries on once the signs are done.`n`nOFF - keeping the bar on the fish comes first,`nand signs are only clicked while the fish is on`nthe bar.`n`nThe bar drifts while signs are clicked, so you`ncan lose progress on the fish."
Y += RH
SwRetryChk := SwRetryFails ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vSwRetryFails %SwRetryChk% gSwRetryFailsChanged HwndhC, Retry failed clicks
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - if a sign click does not register, the macro`nclicks that sign again (up to 3 times per sign)`ninstead of giving up on the signs for this cast.`nFailed clicks are spotted sooner than with it off,`nand retries are spaced out, never spam clicked.`n`nIt never clicks a sign that looks like a different`nzodiac: it looks for the right sign on the bar and`nclicks that one, and only gives up if it is not there.`n`nOFF - a failed click stops sign clicking for`nthe rest of the cast."
Y += RH
SwMaxChk := SwMaxSigns ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vSwMaxSigns %SwMaxChk% gSwMaxSignsChanged HwndhC, Max sign speed
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - pushes sign detection and clicking to the`nlimit: the stars are trusted almost the moment`nthey change, the start of the signs is locked in`nsooner, and each click is held and hovered for`nabout half as long.`n`nExtreme: star changes are read every frame and`ntrusted instantly, every sign already showing is`nclicked in ONE burst without waiting for each star,`nclicks are 10ms hover / 20ms hold, and failed`nclicks are spotted and retried twice as fast.`n`nThe fastest setting, but the most likely to misread`na star or have a click not register. Pair it with`nRetry failed clicks."
Y += RH
SwPasChk := SwPassive ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vSwPassive %SwPasChk% gSwPassiveChanged HwndhC, Passive mode
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - the macro does NOT cast or shake. After you`npress Start it just watches your screen and plays`nthe Stellarwave minigame whenever it shows up,`nthen goes back to watching. You cast yourself.`n`nOFF - normal: the macro casts and shakes too."
Y += RH
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w220 h20 +0x200 HwndhC, Passive scan every (ms)
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Add, Edit, x%IX% y%Y% w80 h20 vSwPassiveMs gSwPassiveChanged HwndhC +Number, %SwPassiveMs%
MgAdd("stellar", hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "How often passive mode looks for the minigame.`nLower = it starts playing sooner, but uses a bit`nmore CPU. 500 is a good default."
Y += RH
SwPhChk := SwPassiveHide ? "Checked" : ""
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, CheckBox, x%CX% y%Y% w300 h20 c%ColorText% vSwPassiveHide %SwPhChk% gOverlayOptChanged HwndhC, Hide overlay in passive mode
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "ON - while passive mode is running, the info text`nand the bar overlay are invisible. The macro still`nworks exactly the same.`n`nStop the macro to see them again."
Y += RH
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w220 h20 +0x200 HwndhC, Preset
MgAdd("stellar", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorYellowBGR}
SwPresetChoice := (SwPreset = "Ominous Ouija") ? 2 : 1
Gui, Add, DropDownList, x%IX% y%Y% w%IW% h100 vSwPreset gSwPresetChanged Choose%SwPresetChoice% HwndhC, Normal|Ominous Ouija
MgAdd("stellar", hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("stellar", hQ)
IconTips[hQ] := "Normal - the zodiac signs.`n`nOminous Ouija - the ouija look: letter tokens that`nspell GRIMPLANCHET. Each token's letter is read`nand they are clicked in that order; when the`ntokens move to new spots they are read again.`n`nEach preset has its own colors in the Stellarwave`ncolor boxes below - they switch when you pick`none. Ominous Ouija: the bar's grey rims, and the`nplanchette as the fish."

; ------------------------------------------------------------------- Requiem reel limits
MgBlockOpen("reel", 204, 70)
ReelFieldDefs := [ ["Min hold (ms)","ReelMinHold"
	, "Once the macro presses the mouse it will not`nrelease for at least this long.`n`nRaise it if the reel keeps snapping.`nToo high = sluggish, overshoots the fish."]
	, ["Min release (ms)","ReelMinRelease"
	, "Once the macro releases it will not press again`nfor at least this long.`n`nRaise it if the reel keeps snapping.`nToo high = sluggish, falls behind the fish."] ]
Y := 216
for i, d in ReelFieldDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	MgAdd("reel", hL)
	SpecialBrushes[hL] := {brush: hBrushCard, text: ColorYellowBGR}
	EdOpt := TmNumOpt(var)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %EdOpt%, % %var%
	MgAdd("reel", hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	MgAdd("reel", hQ)
	IconTips[hQ] := hint
	Y += RH
	}

; ----------------------------------------------------------- Remembrance: living / departed
MgBlockOpen("remem", 204, 96)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y212 w%TXW% h16 HwndhL, REMEMBRANCE
MgAdd("remem", hL)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Y := 236
Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, Rod state:
MgAdd("remem", hL)
SpecialBrushes[hL] := {brush: hBrushCard, text: ColorYellowBGR}
RemembranceChoice := (RemembranceMode = "Departed") ? 2 : 1
Gui, Add, DropDownList, x%IX% y%Y% w%IW% h100 vRemembranceMode gRemembranceModeChanged Choose%RemembranceChoice% HwndhC, Living|Departed
MgAdd("remem", hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
MgAdd("remem", hQ)
IconTips[hQ] := "Which state the rod is in.`n`nBoth states put a second, BLACK fish line on the`nbar, and you want to stay off it.`n`nLIVING - sitting on both lines PAUSES progress,`nso the bar still takes the white line when the two`nare too close to separate.`n`nDEPARTED - sitting on both LOSES progress, so the`nbar keeps clear of the black line even if it has to`ngive up the white one for a moment."
Y += RH
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y%Y% w%TXW% h20 +0x200 HwndhL, Switching state re-fills the bar colors - they differ between the two.
MgAdd("remem", hL)
SpecialBrushes[hL] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

; --------------------------------------------------------------------------- manual steering
TuningFieldDefs := [ ["Stable Right Multiplier","StableRightMultiplier"
	, "GAS PEDAL for moving RIGHT.`n`nTOO HIGH  = shoots past the fish.`nTOO LOW   = never catches up to it."]
	, ["Stable Right Division","StableRightDivision"
	, "BRAKES after moving right.`n`nBIGGER number = WEAKER brakes (slides past).`nSMALLER number = STRONGER brakes (stops early).`n`nYes, it works backwards."]
	, ["Stable Left Multiplier","StableLeftMultiplier"
	, "GAS PEDAL for moving LEFT.`n`nTOO HIGH  = shoots past the fish.`nTOO LOW   = never catches up to it."]
	, ["Stable Left Division","StableLeftDivision"
	, "BRAKES after moving left.`n`nBIGGER number = WEAKER brakes (slides past).`nSMALLER number = STRONGER brakes (stops early).`n`nYes, it works backwards."]
	, ["Unstable Right Multiplier","UnstableRightMultiplier"
	, "Gas pedal for RIGHT, used only when the macro`nCANNOT SEE the bar and is guessing.`n`nTOO HIGH = shoots past.  TOO LOW = too slow."]
	, ["Unstable Right Division","UnstableRightDivision"
	, "Brakes for the guessing right move.`n`nBIGGER = weaker brakes.`nSMALLER = stronger brakes."]
	, ["Unstable Left Multiplier","UnstableLeftMultiplier"
	, "Gas pedal for LEFT, used only when the macro`nCANNOT SEE the bar and is guessing.`n`nTOO HIGH = shoots past.  TOO LOW = too slow."]
	, ["Unstable Left Division","UnstableLeftDivision"
	, "Brakes for the guessing left move.`n`nBIGGER = weaker brakes.`nSMALLER = stronger brakes."]
	, ["Right Ankle Break Multiplier","RightAnkleBreakMultiplier"
	, "Tiny PAUSE before turning around to go right.`n`nTOO HIGH = smooth but slow to react.`nTOO LOW  = jittery, shakes back and forth."]
	, ["Left Ankle Break Multiplier","LeftAnkleBreakMultiplier"
	, "Tiny PAUSE before turning around to go left.`n`nTOO HIGH = smooth but slow to react.`nTOO LOW  = jittery, shakes back and forth."] ]

MgBlockOpen("manual", 456, 288)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y466 w%TXW% h16 HwndhC, MANUAL STEERING
MgAdd("manual", hC)
Gui, Font, s9 c%ColorDark%, Segoe UI
Gui, Add, Text, x%CX% y486 w%TXW% h22 +0x200 HwndhWarn, ⚠  Wrong values break tracking. Hover a ? to learn more.
MgAdd("manual", hWarn)
SpecialBrushes[hWarn] := {brush: hBrushAmber, text: ColorDarkBGR}
RoundCtrl(hWarn, TXW, 22, 6)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 516
for i, d in TuningFieldDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	MgAdd("manual", hL)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC, % %var%
	MgAdd("manual", hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	MgAdd("manual", hQ)
	IconTips[hQ] := hint
	Y += 24
	}

; ------------------------------------------------------------------------ precision steering
PrecisionFieldDefs := [ ["Kp","Kp"
	, "How hard it steers based on DISTANCE from`nthe fish.`n`nTOO HIGH = overshoots and wobbles.`nTOO LOW  = drifts, never quite arrives.`n`nSafe range: 0.3 to 0.8."]
	, ["Kd","Kd"
	, "How hard it steers based on SPEED. This is`nthe part Manual mode has no equivalent for --`nit accounts for the fish MOVING.`n`nTOO HIGH = sluggish, over-damped.`nTOO LOW  = oscillates around the fish.`n`nThis is the most important value here."]
	, ["Velocity Smoothing","VelocitySmoothing"
	, "How much it trusts the newest speed reading.`n0.2 means 20% new, 80% history.`n`nHIGHER = reacts faster but jitters more.`nLOWER  = smoother but slower to notice a`nchange of direction."]
	, ["Stopping Distance","StoppingDistanceMultiplier"
	, "How early it starts braking, measured in`nspeed. Faster closing = brakes sooner.`n`nTOO HIGH = brakes way too early, crawls.`nTOO LOW  = sails straight past the fish."] ]

MgBlockOpen("precision", 456, 144)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y466 w%TXW% h16 HwndhC, PRECISION STEERING
MgAdd("precision", hC)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 488
for i, d in PrecisionFieldDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	MgAdd("precision", hL)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC, % %var%
	MgAdd("precision", hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	MgAdd("precision", hQ)
	IconTips[hQ] := hint
	Y += 24
	}

; ------------------------------------------------------------------------------- bar behaviour
MgBlockOpen("barctl", 620, 142)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y630 w%TXW% h16 HwndhC, BAR BEHAVIOUR
MgAdd("barctl", hC)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

Y := 652
MinigameFieldDefs := [ ["Minigame failsafe (s)","BarCalculationFailsafe",1
	, "Max SECONDS for one minigame (including waiting`nfor the bar). If it runs over, the macro re-equips`nthe rod and starts a fresh cast.`n`nDefault 60."]
	, ["Stabilizer clicks","StabilizerLoop",1
	, "Rapid clicks after each move to hold the bar`nstill. Lower control = increase (12-14)`n`nHIGHER = steadier, holds position better.`nLOWER = reacts faster."]
	, ["Side bar ratio","SideBarRatio",0
	, "How far in from the edges the amber markers sit.`n`nHIGHER = markers move inward, so the macro`nstarts edge-holding sooner.`nLOWER = markers sit closer to the edges."]
	, ["Side wait multiplier","SideBarWaitMultiplier",0
	, "How long it waits at the far edges before`ncoming back.`n`nHIGHER = waits longer (less bouncing).`nLOWER = leaves the edge sooner."] ]

for i, d in MinigameFieldDefs
	{
	lbl := d[1]
	var := d[2]
	isInt := d[3]
	hint := d[4]
	opt := isInt ? "+Number" : ""
	Gui, Add, Text, x%CX% y%Y% w%LW% h20 HwndhL, %lbl%:
	MgAdd("barctl", hL)
	Gui, Add, Edit, x%IX% y%Y% w%IW% h20 v%var% gQueueAutoSave HwndhC %opt%, % %var%
	MgAdd("barctl", hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%Y% w16 h20 Center +0x100 +0x200 HwndhQ, ?
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	MgAdd("barctl", hQ)
	IconTips[hQ] := hint
	Y += RH
	}

; ------------------------------------------------------------------------------- quick rules
MgBlockOpen("manrules", 800, 158)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y810 w%TXW% h16 HwndhC, QUICK RULES — MANUAL
MgAdd("manrules", hC)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
ManualTipsLines := ["• RIGHT values should be HIGHER than LEFT values."
	, "• UNSTABLE values should be HIGHER than STABLE values."
	, "• Keep every Division between 1.0 and 1.5."
	, "• Overshoots the fish? Lower the Multiplier."
	, "• Too slow to catch up? Raise the Multiplier."
	, "• Change ONE value at a time, by about 15%."]
RuleY := 832
for i, RuleTxt in ManualTipsLines
	{
	Gui, Add, Text, x%CX% y%RuleY% w%TXW% h16 cFFFFFF HwndhC, %RuleTxt%
	MgAdd("manrules", hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}
	RuleY += 16
	}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

MgBlockOpen("precrules", 800, 186)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y810 w%TXW% h16 HwndhC, QUICK RULES — PRECISION / LINES
MgAdd("precrules", hC)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
PrecTipsLines := ["• Try the defaults FIRST. Precision needs far less"
	, "   tuning than Manual — usually none at all."
	, "• Wobbles or shakes on the fish? Raise Kd."
	, "• Slow to catch a fish that bolts? Raise Kp."
	, "• Sails past the fish? Raise Stopping Distance."
	, "• Crawls and never arrives? Lower Stopping Distance."
	, "• Kd matters most. Kp near 0.5 and Kd near 0.3 is a"
	, "   good place to start."
	, "• Change ONE value at a time, by about 0.1."]
RuleY := 832
for i, RuleTxt in PrecTipsLines
	{
	Gui, Add, Text, x%CX% y%RuleY% w%TXW% h16 cFFFFFF HwndhC, %RuleTxt%
	MgAdd("precrules", hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}
	RuleY += 16
	}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

; ------------------------------------------------------------------------ live detection check
MgBlockOpen("detcheck", 1000, 88)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y1009 w%TXW% h16 HwndhC, DETECTION CHECK
MgAdd("detcheck", hC)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y1029 w170 h28 Center +0x100 +0x200 vDetTestBtn gDetTestToggle HwndhC, ▶  Test detection
MgAdd("detcheck", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 170, 28, 7)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
Gui, Add, Text, x386 y1029 w342 h28 +0x200 vDetTestOut HwndhC, Stop the macro first`, then press Test.
MgAdd("detcheck", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y1060 w%TXW% h16 HwndhC, Press Test, then cast your rod and play a minigame to see what it picks up.
MgAdd("detcheck", hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

return
;====================================================================================================;
;====================================================================================================;

BuildUtilitiesSection:

Gui, Font, s13 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w%CARDW% h30 HwndhUH, Fishing Utilities
UtilCtrls.Push(hUH)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CARDX% y152 w%CARDW% h18 HwndhUS, Extras that run alongside fishing. Turn one on and open it to set it up.
UtilCtrls.Push(hUS)
SpecialBrushes[hUS] := {brush: hBrushBG, text: ColorMutedBGR}

UtilRowDefs := [ ["Auto Totem","UtilTotemOn","UtilTotemToggle","UtilOpenTotem"]
	, ["Auto Aquarium","UtilAquariumOn","UtilAquariumToggle","UtilOpenAquarium"]
	, ["Auto Keeperbound Recharge","UtilKeeperOn","UtilKeeperToggle","UtilOpenKeeper"]
	, ["Stellarwave Auto Retry","UtilGuessOn","UtilGuessToggle","UtilOpenGuess"]
	, ["Discord Webhook","UtilWebhookOn","UtilWebhookToggle","UtilOpenWebhook"] ]

UtilRowY := 180
for i, d in UtilRowDefs
	{
	lbl := d[1]
	cvar := d[2]
	ctog := d[3]
	copen := d[4]
	hC := AddPanel(CARDX, UtilRowY, CARDW, 54)
	UtilCtrls.Push(hC)
	Gui, Font, s10 Bold c%ColorText%, Segoe UI
	UtilLblY := UtilRowY + 17
	Gui, Add, Text, x%CX% y%UtilLblY% w240 h20 HwndhC, %lbl%
	UtilCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
	Gui, Font, s9 Norm c%ColorText%, Segoe UI
	if (cvar = "UtilTotemOn")
		uchk := TotemAuto ? "Checked" : ""
	else if (cvar = "UtilAquariumOn")
		uchk := AquariumAuto ? "Checked" : ""
	else if (cvar = "UtilKeeperOn")
		uchk := KeeperAuto ? "Checked" : ""
	else if (cvar = "UtilGuessOn")
		uchk := SwGuessOn ? "Checked" : ""
	else
		uchk := WebhookOn ? "Checked" : ""
	Gui, Add, CheckBox, x572 y%UtilLblY% w58 h20 c%ColorText% v%cvar% %uchk% g%ctog% HwndhC, On
	UtilCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
	UtilBtnY := UtilRowY + 13
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x642 y%UtilBtnY% w86 h28 Center +0x100 +0x200 g%copen% HwndhC, Open
	UtilCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
	RoundCtrl(hC, 86, 28, 7)
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	UtilRowY += 64
	}

UtilNoteY := UtilRowY + 4
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CARDX% y%UtilNoteY% w%CARDW% h48 HwndhC, More add-ons will appear here as they are added.`nAuto Totem only works in a private server.`nTotem and Aquarium both turn camera mode off - it hides the UI they read.
UtilCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}
Gui, Font, s9 c%ColorMuted%, Segoe UI

return

UtilTotemToggle:
GuiControlGet, UtilTotemOn, 1:, UtilTotemOn
TotemAuto := UtilTotemOn
GuiControl, 1:, TotemAuto, %UtilTotemOn%
gosub, RefreshCameraLock
gosub, ShowSection
gosub, QueueAutoSave
return

UtilWebhookToggle:
GuiControlGet, UtilWebhookOn, 1:, UtilWebhookOn
WebhookOn := UtilWebhookOn
GuiControl, 1:, WebhookOn, %UtilWebhookOn%
gosub, ShowSection
gosub, QueueAutoSave
return

UtilOpenTotem:
TargetSection := "Totem"
gosub, ShowSection
return

UtilAquariumToggle:
GuiControlGet, UtilAquariumOn, 1:, UtilAquariumOn
AquariumAuto := UtilAquariumOn
GuiControl, 1:, AquariumAuto, %UtilAquariumOn%
gosub, RefreshCameraLock
gosub, ShowSection
gosub, QueueAutoSave
return

UtilOpenAquarium:
TargetSection := "Aquarium"
gosub, ShowSection
return

UtilKeeperToggle:
GuiControlGet, UtilKeeperOn, 1:, UtilKeeperOn
KeeperAuto := UtilKeeperOn
GuiControl, 1:, KeeperAuto, %UtilKeeperOn%
gosub, RefreshCameraLock
gosub, ShowSection
gosub, QueueAutoSave
return

UtilOpenKeeper:
TargetSection := "Keeper"
gosub, ShowSection
return

UtilOpenWebhook:
TargetSection := "Webhook"
gosub, ShowSection
return

UtilBack:
TargetSection := "Utilities"
gosub, ShowSection
return

;====================================================================================================;

BuildGuessSection:

Gui, Font, s9 Norm c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w220 h18 +0x100 gUtilBack HwndhC, <  Fishing Add-ons
GuessCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorAccentBGR}

hC := AddPanel(CARDX, 140, CARDW, 50)
GuessCtrls.Push(hC)
Gui, Font, s11 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y155 w300 h20 HwndhC, Stellarwave Auto Retry
GuessCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
SwGuessChk := SwGuessOn ? "Checked" : ""
Gui, Add, CheckBox, x572 y155 w58 h20 c%ColorText% vSwGuessOn %SwGuessChk% gSwGuessChanged HwndhC, On
GuessCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x642 y151 w86 h28 Center +0x100 +0x200 gUtilBack HwndhC, Hide
GuessCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 86, 28, 7)

hC := AddPanel(CARDX, 196, CARDW, 78)
GuessCtrls.Push(hC)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y204 w620 h64 HwndhC, In the last stars it takes over: it works out the best match of the signs that were`nnever clicked to the stars that are left, clicks the best one, and checks if the star lit.`nIf not, it tries the next best. The very last sign is clicked the instant star 11 lights.`nSet the star positions and lit / unlit colors, then press Test with the stars on screen.
GuessCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI

hC := AddPanel(CARDX, 280, CARDW, 214)
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
Gui, Add, Text, x%CX% y292 w140 h20 HwndhC, Star positions:
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x350 y292 w204 h20 +0x200 vSwGuessPtsTxt HwndhC, -
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x562 y290 w96 h24 Center +0x100 +0x200 gSwGuessPickPts HwndhC, Set
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 96, 24, 6)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x666 y290 w62 h24 Center +0x100 +0x200 gSwGuessClearPts HwndhC, Clear
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
RoundCtrl(hC, 62, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y318 w140 h20 HwndhC, Lit star color:
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x350 y318 w204 h20 +0x200 vSwGuessLitTxt HwndhC, -
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x562 y316 w96 h24 Center +0x100 +0x200 gSwGuessPickLit HwndhC, Pick
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 96, 24, 6)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x666 y316 w62 h24 Center +0x100 +0x200 gSwGuessClearLit HwndhC, Clear
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
RoundCtrl(hC, 62, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y344 w140 h20 HwndhC, Unlit star color:
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x350 y344 w204 h20 +0x200 vSwGuessUnTxt HwndhC, -
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x562 y342 w96 h24 Center +0x100 +0x200 gSwGuessPickUn HwndhC, Pick
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 96, 24, 6)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x666 y342 w62 h24 Center +0x100 +0x200 gSwGuessClearUn HwndhC, Clear
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
RoundCtrl(hC, 62, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y374 w%LW% h20 HwndhC, Check wait (ms):
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Add, Edit, x%IX% y374 w%IW% h20 vSwGuessWait gSwGuessNumChanged HwndhC +Number, %SwGuessWait%
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y374 w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorText%, Segoe UI
GuessCtrls.Push(hQ)
GuessBodyCtrls.Push(hQ)
SpecialBrushes[hQ] := {brush: hBrushCard, text: ColorAccentBGR}
IconTips[hQ] := "How long to wait after a click for the star to`nlight up before trying the next sign.`n`nLower is faster. If it calls right signs wrong`n(and wastes clicks), raise it (150-250)."
Gui, Add, Text, x%CX% y400 w%LW% h20 HwndhC, Guess the last (stars):
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Add, Edit, x%IX% y400 w%IW% h20 vSwGuessLastN gSwGuessNumChanged HwndhC +Number, %SwGuessLastN%
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
ThemedCtrls.Push(hC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y400 w16 h20 Center +0x100 +0x200 HwndhQ, ?
Gui, Font, s9 Norm c%ColorText%, Segoe UI
GuessCtrls.Push(hQ)
GuessBodyCtrls.Push(hQ)
SpecialBrushes[hQ] := {brush: hBrushCard, text: ColorAccentBGR}
IconTips[hQ] := "How many of the last stars it guesses on.`n3 means it takes over when 9 of 12 are lit.`nWith 3 left it needs at most 3 wrong clicks.`nAt 1 star left it just clicks the one sign`nthat was never clicked."
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CX% y432 w166 h24 Center +0x100 +0x200 gSwGuessTest HwndhC, Test
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 166, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
SwGGChk := SwGuessGuess ? "Checked" : ""
Gui, Add, CheckBox, x392 y434 w260 h20 c%ColorText% vSwGuessGuess %SwGGChk% gSwGuessGuessChanged HwndhC, Guess on the last stars
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y434 w16 h20 Center +0x100 +0x200 HwndhQ, ?
GuessCtrls.Push(hQ)
GuessBodyCtrls.Push(hQ)
SpecialBrushes[hQ] := {brush: hBrushCard, text: ColorAccentBGR}
IconTips[hQ] := "ON - in the last stars it guesses among the signs`nit never clicked, checking each one.`n`nOFF - no guessing. It only clicks the very last`nsign the moment star 11 lights, because that is`nthe one sign that was never clicked."
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y464 w620 h20 vSwGuessStat HwndhC, -
GuessCtrls.Push(hC)
GuessBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
return

UtilGuessToggle:
GuiControlGet, UtilGuessOn, 1:, UtilGuessOn
SwGuessOn := UtilGuessOn ? true : false
GuiControl, 1:, SwGuessOn, %UtilGuessOn%
gosub, ShowSection
gosub, QueueAutoSave
return

UtilOpenGuess:
TargetSection := "Guess"
gosub, ShowSection
return

SwGuessChanged:
GuiControlGet, SwGuessV, 1:, SwGuessOn
if (!ErrorLevel)
	SwGuessOn := SwGuessV ? true : false
GuiControl, 1:, UtilGuessOn, % (SwGuessOn ? 1 : 0)
gosub, ShowSection
gosub, QueueAutoSave
return

SwGuessGuessChanged:
GuiControlGet, SwGuessV, 1:, SwGuessGuess
if (!ErrorLevel)
	SwGuessGuess := SwGuessV ? true : false
gosub, QueueAutoSave
return

SwGuessNumChanged:
GuiControlGet, SwGuessV, 1:, SwGuessWait
if (!ErrorLevel and SwGuessV != "")
	SwGuessWait := SwGuessV
GuiControlGet, SwGuessV, 1:, SwGuessLastN
if (!ErrorLevel and SwGuessV != "")
	SwGuessLastN := SwGuessV
gosub, QueueAutoSave
return

SwGuessRefresh:
GuiControl, 1:, SwGuessPtsTxt, % (SwGuessParse() ? "12 stars set" : "not set")
SwGuessC := SwGuessLit
if SwGuessC is number
	SwGuessT := (SwGuessC >= 0) ? "picked " . Format("#{:06X}", SwGuessC) : "not picked"
else
	SwGuessT := "not picked"
GuiControl, 1:, SwGuessLitTxt, %SwGuessT%
SwGuessC := SwGuessUnlit
if SwGuessC is number
	SwGuessT := (SwGuessC >= 0) ? "picked " . Format("#{:06X}", SwGuessC) : "not picked"
else
	SwGuessT := "not picked"
GuiControl, 1:, SwGuessUnTxt, %SwGuessT%
GuiControl, 1:, SwGuessStat, % (SwGuessMsg != "") ? "Last run - " . SwGuessMsg : "Not run yet."
return

SwGuessClearPts:
SwGuessPts := ""
gosub, SwGuessRefresh
gosub, QueueAutoSave
return

SwGuessClearLit:
SwGuessLit := -1
gosub, SwGuessRefresh
gosub, QueueAutoSave
return

SwGuessClearUn:
SwGuessUnlit := -1
gosub, SwGuessRefresh
gosub, QueueAutoSave
return

SwGuessPickPts:
gosub, KeeperFindRoblox
if (!RobloxHwnd)
	{
	msgbox, 4144, DeepFish, Could not find the Roblox window. Start Roblox first.
	return
	}
RobloxClientRect(RobloxHwnd, GwX, GwY, GwW, GwH)
Gui, Hide
WinActivate, ahk_id %RobloxHwnd%
Sleep 250
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
GPts := []
GCancel := false
GUWas := true
Loop
	{
	if KeyHeld("Escape")
		{
		GCancel := true
		break
		}
	GUNow := KeyHeld("u")
	if (GUNow and !GUWas)
		{
		MouseGetPos, GMx, GMy
		GPts.Push([GMx - GwX, GMy - GwY])
		if (GPts.Length() >= 2)
			break
		}
	GUWas := GUNow
	MouseGetPos, GMx, GMy
	GTip := (GPts.Length() = 0) ? "Press U on the CENTER of star 1 (far LEFT star)" : "Now press U on the CENTER of star 12 (far RIGHT star)"
	ToolTip, %GTip%`nThe 10 in between are filled in evenly`nEsc to cancel, % GMx + 26, % GMy + 30, 20
	Sleep 20
	}
ToolTip, , , , 20
CoordMode, Mouse, Client
CoordMode, ToolTip, Relative
if (!GCancel)
	{
	GS := ""
	Loop 12
		{
		Gf := (A_Index - 1) / 11
		Gx := Round(GPts[1][1] + (GPts[2][1] - GPts[1][1]) * Gf)
		Gy := Round(GPts[1][2] + (GPts[2][2] - GPts[1][2]) * Gf)
		GS .= ((A_Index > 1) ? "|" : "") . Gx . "," . Gy
		}
	SwGuessPts := GS
	gosub, QueueAutoSave
	}
Gui, Show
TargetSection := "Guess"
gosub, ShowSection
return

SwGuessPickLit:
SwGuessWhat := "lit"
gosub, SwGuessPickColor
return

SwGuessPickUn:
SwGuessWhat := "unlit"
gosub, SwGuessPickColor
return

SwGuessPickColor:
Gui, Hide
Sleep 250
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
GCancel := false
GPc := ""
Loop
	{
	if KeyHeld("Escape")
		{
		GCancel := true
		break
		}
	if KeyHeld("u")
		{
		MouseGetPos, GMx, GMy
		PixelGetColor, GPc, %GMx%, %GMy%, RGB
		while KeyHeld("u")
			Sleep 20
		break
		}
	MouseGetPos, GMx, GMy
	PixelGetColor, GHov, %GMx%, %GMy%, RGB
	ToolTip, % "Press U on the CENTER of a" . ((SwGuessWhat = "lit") ? " LIT (done)" : "n UNLIT (not done)") . " star`nColor under the mouse: " . GHov . "`nEsc to cancel", % GMx + 26, % GMy + 30, 20
	Sleep 30
	}
ToolTip, , , , 20
CoordMode, Mouse, Client
CoordMode, Pixel, Client
CoordMode, ToolTip, Relative
if (!GCancel and GPc != "")
	{
	if (SwGuessWhat = "lit")
		SwGuessLit := GPc + 0
	else
		SwGuessUnlit := GPc + 0
	gosub, QueueAutoSave
	}
Gui, Show
TargetSection := "Guess"
gosub, ShowSection
return

SwGuessTest:
gosub, KeeperFindRoblox
if (!RobloxHwnd)
	{
	msgbox, 4144, DeepFish, Could not find the Roblox window. Start Roblox first.
	return
	}
Gui, Hide
WinActivate, ahk_id %RobloxHwnd%
WinWaitActive, ahk_id %RobloxHwnd%, , 2
Sleep 300
GN := SwGuessStars()
Gui, Show
TargetSection := "Guess"
gosub, ShowSection
if (GN < 0)
	{
	msgbox, 4144, DeepFish, Set the star positions and both colors first.
	return
	}
GRow := ""
Loop 12
	GRow .= A_Index . (SwGuessState[A_Index] ? "=LIT  " : "=off  ") . ((A_Index = 6) ? "`n" : "")
msgbox, 4160, DeepFish, % "Stars lit in a row from the left: " . GN . "`n`n" . GRow . "`n`nIt takes over once " . (12 - SwGuessN()) . " or more are lit."
return

BuildAdvancedSection:
Gui, Font, s9 Norm c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w220 h18 +0x100 gAdvBack HwndhC, <  General
AdvCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorAccentBGR}
Gui, Font, s13 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CARDX% y140 w400 h28 HwndhC, Advanced timings
AdvCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x562 y142 w166 h24 Center +0x100 +0x200 gAdvResetAll HwndhC, Reset all to default
AdvCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorAccentBGR}
RoundCtrl(hC, 166, 24, 6)
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CARDX% y172 w%CARDW% h32 HwndhC, Only used while Advanced settings is ON (General). Empty a box to put it back to its default.`nms = milliseconds, s = seconds. Settings marked * are the same boxes as on their own pages.
AdvCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}
AdvY := 212
AdvGrp := ""
AdvIdx := 0
AdvMap := {}
for i, e in AdvRegistry()
	{
	if (e[1] != AdvGrp)
		{
		AdvGrp := e[1]
		AdvY += 6
		Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
		Gui, Add, Text, x%CARDX% y%AdvY% w400 h16 HwndhC, % Format("{:U}", AdvGrp)
		AdvCtrls.Push(hC)
		SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}
		AdvY += 20
		}
	AdvIdx++
	AdvMap[AdvIdx] := e
	AdvUL := StrSplit(e[5], "|")
	AdvLbl := AdvUL[2] . ((e[2] = "V") ? "  *" : "")
	Gui, Font, s9 Norm c%ColorText%, Segoe UI
	Gui, Add, Text, x%CX% y%AdvY% w380 h20 +0x200 HwndhC, %AdvLbl%
	AdvCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushBG, text: ColorTextBGR}
	Gui, Add, Edit, x592 y%AdvY% w70 h20 vAdvE%AdvIdx% gAdvEdited HwndhC
	AdvCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
	AdvDef := (e[2] = "L") ? AdvUL[1] . "  (def " . e[4] . ")" : AdvUL[1]
	Gui, Add, Text, x668 y%AdvY% w90 h20 +0x200 HwndhC, %AdvDef%
	AdvCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}
	AdvY += 24
	}
AdvBuilt := true
return

AdvRefresh:
if (!AdvBuilt)
	return
if (!IsObject(AdvT))
	AdvLoad()
AdvRefreshing := true
for idx, e in AdvMap
	{
	if (e[2] = "V")
		{
		AdvVn := e[3]
		AdvV := %AdvVn%
		}
	else
		AdvV := AdvT.HasKey(e[3]) ? AdvT[e[3]] : ""
	GuiControl, 1:, AdvE%idx%, %AdvV%
	}
AdvRefreshing := false
return

AdvEdited:
if (AdvRefreshing)
	return
AdvIdx := SubStr(A_GuiControl, 5) + 0
AdvE := AdvMap[AdvIdx]
if (!IsObject(AdvE))
	return
GuiControlGet, AdvV, 1:, %A_GuiControl%
AdvV := Trim(AdvV)
if (!IsObject(AdvT))
	AdvLoad()
if (AdvE[2] = "V")
	{
	if AdvV is not number
		return
	AdvVn := AdvE[3]
	%AdvVn% := AdvV + 0
	GuiControl, 1:, %AdvVn%, %AdvV%
	gosub, QueueAutoSave
	return
	}
if (AdvV = "")
	{
	AdvT.Delete(AdvE[3])
	IniDelete, %SettingsFile%, Advanced, % AdvE[3]
	return
	}
if AdvV is not number
	return
AdvT[AdvE[3]] := AdvV + 0
IniWrite, %AdvV%, %SettingsFile%, Advanced, % AdvE[3]
return

AdvResetAll:
MsgBox, 0x24, DeepFish, Put every hidden timing on this page back to its default?`n`n(Settings marked * keep their values.)
IfMsgBox, No
	return
IniDelete, %SettingsFile%, Advanced
AdvT := {}
gosub, AdvRefresh
return

AdvancedOnChanged:
GuiControlGet, AdvOnV, 1:, AdvancedOn
if (!ErrorLevel)
	AdvancedOn := AdvOnV ? true : false
gosub, QueueAutoSave
if (AdvancedOn)
	gosub, AdvOpen
return

AdvOpen:
TargetSection := "Advanced"
gosub, ShowSection
return

AdvBack:
TargetSection := "General"
gosub, ShowSection
return

BuildKeeperSection:

Gui, Font, s9 Norm c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w220 h18 +0x100 gUtilBack HwndhC, <  Fishing Add-ons
KeeperCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorAccentBGR}

hC := AddPanel(CARDX, 140, CARDW, 50)
KeeperCtrls.Push(hC)
Gui, Font, s11 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y155 w300 h20 HwndhC, Auto Keeperbound Recharge
KeeperCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KBchk := KeeperAuto ? "Checked" : ""
Gui, Add, CheckBox, x572 y155 w58 h20 c%ColorText% vKeeperAuto %KBchk% gKeeperAutoChanged HwndhC, On
KeeperCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x642 y151 w86 h28 Center +0x100 +0x200 gUtilBack HwndhC, Hide
KeeperCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 86, 28, 7)

; ---- the gamepass requirement, stated up front ----
hC := AddPanel(CARDX, 196, CARDW, 58)
KeeperCtrls.Push(hC)
Gui, Font, s9 Bold cFFC24B, Segoe UI
Gui, Add, Text, x%CX% y206 w620 h18 HwndhC, Requires the ENCHANT ANYWHERE gamepass - without it this does nothing.
KeeperCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: 0x4BC2FF}
Gui, Add, Text, x%CX% y226 w620 h18 HwndhC, You MUST manually recharge ONCE before starting the macro.
KeeperCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: 0x4BC2FF}
Gui, Font, s9 Norm c%ColorText%, Segoe UI

hC := AddPanel(CARDX, 260, CARDW, 512)
KeeperCtrls.Push(hC)
KeeperBodyCtrls.Push(hC)

KbFieldDefs := [ ["Wait before recharge (ms)","KeeperPreDelay","num"
	, "How long to wait after a catch before the`nrecharge starts. 0 = start right away.`n`nRaise it if the catch popup or the game is still`nbusy when the recharge begins."]
	, ["Every (catches)","KeeperEveryCatches","num"
	, "How many catches between recharges.`n`nA Keeperbound rod loses about 0.2% power per`ncatch, so 50 catches is roughly 10% lost."]
	, ["Recharges per trip","KeeperRecharges","num"
	, "How many times to enchant in one visit.`n`nEach one refills about 5% power, so two`nrecharges covers the drain from 50 catches."]
	, ["Relic hotbar key","KeeperRelicKey","str"
	, "The hotbar number your Enchant Relic sits on.`n`nPut the relic in a hotbar slot and type that`nnumber here."]
	, ["Inventory key","KeeperInvKey","str"
	, "The key that opens the inventory.`n`nG in Fisch - the game prints Press (G) To Open`nabove the hotbar."]
	, ["Between relics (ms)","KeeperBetweenDelay","num"
	, "Pause between one enchant and the next.`n`nToo quick and the game only registers the`nfirst one, so keep this around 2000."]
	, ["Step delay (ms)","KeeperStepDelay","num"
	, "Pause after each click, so the game keeps up."]
	, ["Menu delay (ms)","KeeperOpenDelay","num"
	, "Pause after opening or closing the inventory."]
	, ["Check every (catches)","KeeperOcrEvery","num"
	, "How many catches between checks of the power`nbar (auto % or power line). A check is instant,`nso 1 is fine."]
	, ["Color tolerance","KeeperLineTol","num"
	, "How far a pixel on the line may be from the bar`ncolor you picked and still count as the bar.`n`nRaise it (60-80) if Test says pixels are off`nwhile the bar is full. Lower it (20-30) if it`nnever notices the bar dropping."] ]

KbY := 266
for i, d in KbFieldDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[4]
	Gui, Add, Text, x%CX% y%KbY% w%LW% h20 HwndhKC, %lbl%:
	KeeperCtrls.Push(hKC)
	KeeperBodyCtrls.Push(hKC)
	SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorTextBGR}
	if (d[3] = "num")
		{
		EdOpt := TmNumOpt(var)
		Gui, Add, Edit, x%IX% y%KbY% w%IW% h20 v%var% gQueueAutoSave HwndhKC %EdOpt%, % %var%
		}
	else
		Gui, Add, Edit, x%IX% y%KbY% w%IW% h20 v%var% gQueueAutoSave HwndhKC, % %var%
	KeeperCtrls.Push(hKC)
	KeeperBodyCtrls.Push(hKC)
	ThemedCtrls.Push(hKC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%KbY% w16 h20 Center +0x100 +0x200 HwndhKQ, ?
	Gui, Font, s9 Norm c%ColorText%, Segoe UI
	KeeperCtrls.Push(hKQ)
	KeeperBodyCtrls.Push(hKQ)
	SpecialBrushes[hKQ] := {brush: hBrushCard, text: ColorAccentBGR}
	IconTips[hKQ] := hint
	KbY += 22
	}

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
KbSecY := KbY + 2
Gui, Add, Text, x%CX% y%KbSecY% w400 h16 HwndhKC, BUTTON POSITIONS
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KbY := KbSecY + 18

KbPosDefs := [ ["Enchant Rod", "KbEnchantSpot", "KeeperPickEnchant", "KeeperClearEnchant"]
	, ["Confirm", "KbConfirmSpot", "KeeperPickConfirm", "KeeperClearConfirm"] ]
for i, d in KbPosDefs
	{
	plbl := d[1]
	pvar := d[2]
	pset := d[3]
	pclr := d[4]
	Gui, Add, Text, x%CX% y%KbY% w120 h20 HwndhKC, %plbl%:
	KeeperCtrls.Push(hKC)
	KeeperBodyCtrls.Push(hKC)
	SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorTextBGR}
	Gui, Font, s8 c%ColorMuted%, Segoe UI
	Gui, Add, Text, x330 y%KbY% w224 h20 +0x200 v%pvar% HwndhKC, -
	KeeperCtrls.Push(hKC)
	KeeperBodyCtrls.Push(hKC)
	SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	KbBtnY := KbY - 2
	Gui, Add, Text, x562 y%KbBtnY% w96 h24 Center +0x100 +0x200 g%pset% HwndhKC, Set
	KeeperCtrls.Push(hKC)
	KeeperBodyCtrls.Push(hKC)
	SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorAccentBGR}
	RoundCtrl(hKC, 96, 24, 6)
	Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
	Gui, Add, Text, x666 y%KbBtnY% w62 h24 Center +0x100 +0x200 g%pclr% HwndhKC, Clear
	KeeperCtrls.Push(hKC)
	KeeperBodyCtrls.Push(hKC)
	SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
	RoundCtrl(hKC, 62, 24, 6)
	Gui, Font, s9 Norm c%ColorText%, Segoe UI
	KbY += 26
	}

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
KbSecY := KbY + 2
Gui, Add, Text, x%CX% y%KbSecY% w400 h16 HwndhKC, POWER BAR
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KbY := KbSecY + 18
KbAbChk := KeeperAutoBar ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%KbY% w280 h20 c%ColorText% vKeeperAutoBar %KbAbChk% gKeeperAutoBarChanged HwndhKC, Auto-read the power bar `% (no setup)
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x490 y%KbY% w16 h20 Center +0x100 +0x200 HwndhKQ, ?
KeeperCtrls.Push(hKQ)
KeeperBodyCtrls.Push(hKQ)
SpecialBrushes[hKQ] := {brush: hBrushCard, text: ColorAccentBGR}
IconTips[hKQ] := "EASIEST - nothing to set up.`n`nThe macro finds the purple power bar above your`nhotbar by itself (the one that says 68.3`% Power)`nand reads how full it is. When it drops below the`n`% you set, it recharges.`n`nJust hold your Keeperbound rod so the bar shows,`nthen press Test to check it can see it.`n`nIf the bar is not found it falls back to the power`nline below (if set), or to counting catches."
KbBtnY := KbY - 2
Gui, Add, Text, x562 y%KbBtnY% w166 h24 Center +0x100 +0x200 gKeeperTestAuto HwndhKC, Test
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hKC, 166, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KbY += 26
Gui, Add, Text, x%CX% y%KbY% w%LW% h20 HwndhKC, Recharge below (`%):
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Add, Edit, x%IX% y%KbY% w%IW% h20 vKeeperAutoPct gQueueAutoSave HwndhKC, %KeeperAutoPct%
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
ThemedCtrls.Push(hKC)
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y%KbY% w16 h20 Center +0x100 +0x200 HwndhKQ, ?
KeeperCtrls.Push(hKQ)
KeeperBodyCtrls.Push(hKQ)
SpecialBrushes[hKQ] := {brush: hBrushCard, text: ColorAccentBGR}
IconTips[hKQ] := "Recharges when the power bar reads lower than this.`n`n15 = recharge once it falls under 15`%.`nEach recharge adds about 5`%, so raise Recharges`nper trip if you set this low."
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KbY += 26
KbOcrChk := KeeperOcrOn ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%KbY% w280 h20 c%ColorText% vKeeperOcrOn %KbOcrChk% gKeeperOcrChanged HwndhKC, Or use a power line (manual)
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x490 y%KbY% w16 h20 Center +0x100 +0x200 HwndhKQ, ?
KeeperCtrls.Push(hKQ)
KeeperBodyCtrls.Push(hKQ)
SpecialBrushes[hKQ] := {brush: hBrushCard, text: ColorAccentBGR}
IconTips[hKQ] := "ON - instead of recharging every X catches, the`nmacro looks at an up-down line you place on the`npower bar. When the line is no longer the bar`ncolor you picked, the bar has drained past it,`nso it recharges.`n`n1. Power line - Set, then put the line across the`n   bar at the % you want it to recharge at (e.g.`n   95%), from the top of the bar to the bottom.`n   Keep it off the white text.`n2. Bar color - Pick, press U on the filled bar.`n3. Test while the bar is full: it should say NOT.`n`nOFF - recharges every X catches like before."
KbBtnY := KbY - 2
Gui, Add, Text, x562 y%KbBtnY% w166 h24 Center +0x100 +0x200 gKeeperTestLine HwndhKC, Test
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hKC, 166, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KbY += 26
Gui, Add, Text, x%CX% y%KbY% w120 h20 HwndhKC, Power line:
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x330 y%KbY% w224 h20 +0x200 vKbLineSpot HwndhKC, -
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
KbBtnY := KbY - 2
Gui, Add, Text, x562 y%KbBtnY% w96 h24 Center +0x100 +0x200 gKeeperSetLine HwndhKC, Set
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hKC, 96, 24, 6)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x666 y%KbBtnY% w62 h24 Center +0x100 +0x200 gKeeperClearLine HwndhKC, Clear
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
RoundCtrl(hKC, 62, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KbY += 26
Gui, Add, Text, x%CX% y%KbY% w120 h20 HwndhKC, Bar color:
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x330 y%KbY% w224 h20 +0x200 vKbColorSpot HwndhKC, -
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
KbBtnY := KbY - 2
Gui, Add, Text, x562 y%KbBtnY% w96 h24 Center +0x100 +0x200 gKeeperPickColor HwndhKC, Pick
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hKC, 96, 24, 6)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x666 y%KbBtnY% w62 h24 Center +0x100 +0x200 gKeeperClearColor HwndhKC, Clear
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}
RoundCtrl(hKC, 62, 24, 6)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
KbY += 26
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
KbStatY := KbY + 2
Gui, Add, Text, x%CX% y%KbStatY% w620 h20 vKbStatLine HwndhKC, Idle.
KeeperCtrls.Push(hKC)
KeeperBodyCtrls.Push(hKC)
SpecialBrushes[hKC] := {brush: hBrushCard, text: ColorMutedBGR}

return

KeeperAutoChanged:
GuiControlGet, KeeperAuto, 1:, KeeperAuto
GuiControl, 1:, UtilKeeperOn, % (KeeperAuto ? 1 : 0)
gosub, RefreshCameraLock
gosub, ShowSection
gosub, QueueAutoSave
return

KeeperRefreshSpots:
if (Round(KeeperEnchantX) > 0 and Round(KeeperEnchantY) > 0)
	KbTxt := "set to " . Round(KeeperEnchantX) . ", " . Round(KeeperEnchantY)
else
	KbTxt := "not set - found by looking"
GuiControl, 1:, KbEnchantSpot, %KbTxt%
if (Round(KeeperConfirmX) > 0 and Round(KeeperConfirmY) > 0)
	KbTxt := "set to " . Round(KeeperConfirmX) . ", " . Round(KeeperConfirmY)
else
	KbTxt := "not set - found by looking"
GuiControl, 1:, KbConfirmSpot, %KbTxt%
if (Abs(Round(KeeperLineY2) - Round(KeeperLineY1)) >= 2)
	KbTxt := Round(Abs(KeeperLineY2 - KeeperLineY1)) + 1 . " px tall at x " . Round(KeeperLineX)
else
	KbTxt := "not set"
GuiControl, 1:, KbLineSpot, %KbTxt%
KbCol := KeeperLineColor
if KbCol is number
	{
	if (KbCol >= 0)
		KbTxt := "picked " . Format("#{:06X}", KbCol)
	else
		KbTxt := "not picked"
	}
else
	KbTxt := "not picked"
GuiControl, 1:, KbColorSpot, %KbTxt%
return

KeeperClearEnchant:
KeeperEnchantX := 0
KeeperEnchantY := 0
gosub, KeeperRefreshSpots
gosub, QueueAutoSave
return

KeeperClearConfirm:
KeeperConfirmX := 0
KeeperConfirmY := 0
gosub, KeeperRefreshSpots
gosub, QueueAutoSave
return

KeeperPickEnchant:
KbPickWhat := "enchant"
KbPickMsg := "Press U over the ""Enchant Rod"" button        (open your inventory first)`nEsc to cancel"
gosub, KeeperPickPos
return

KeeperPickConfirm:
KbPickWhat := "confirm"
KbPickMsg := "Press U over the ""Confirm"" button        (press Enchant Rod first)`nEsc to cancel"
gosub, KeeperPickPos
return

KeeperPickPos:
Gui, Hide
Sleep, % Tm(250)
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
KbPickCancel := false
KbPx := 0
KbPy := 0
Loop
	{
	if KeyHeld("Escape")
		{
		KbPickCancel := true
		break
		}
	if KeyHeld("u")
		{
		MouseGetPos, KbPx, KbPy
		while KeyHeld("u")
			Sleep, % Tm(20)
		break
		}
	MouseGetPos, KbMx, KbMy
	ToolTip, %KbPickMsg%, % KbMx + 26, % KbMy + 30, 20
	Sleep, % Tm(25)
	}
ToolTip, , , , 20
CoordMode, Mouse, Client
CoordMode, ToolTip, Relative
if (!KbPickCancel)
	{
	if (!RobloxHwnd or !WinExist("ahk_id " . RobloxHwnd))
		{
		WinGet, RobloxHwnd, ID, ahk_exe RobloxPlayerBeta.exe
		if (!RobloxHwnd)
			WinGet, RobloxHwnd, ID, Roblox
		}
	if (!RobloxHwnd)
		{
		msgbox, 4144, DeepFish, Could not find the Roblox window, so that position cannot be saved.`n`nStart Roblox first, then set the positions again.
		Gui, Show
		TargetSection := "Keeper"
		gosub, ShowSection
		gosub, KeeperRefreshSpots
		return
		}
	VarSetCapacity(KbPt, 8, 0)
	NumPut(KbPx, KbPt, 0, "Int")
	NumPut(KbPy, KbPt, 4, "Int")
	DllCall("ScreenToClient", "Ptr", RobloxHwnd, "Ptr", &KbPt)
	KbCliX := NumGet(KbPt, 0, "Int")
	KbCliY := NumGet(KbPt, 4, "Int")
	VarSetCapacity(KbRc, 16, 0)
	DllCall("GetClientRect", "Ptr", RobloxHwnd, "Ptr", &KbRc)
	KbCw := NumGet(KbRc, 8, "Int")
	KbCh := NumGet(KbRc, 12, "Int")
	if (KbCliX < 0 or KbCliY < 0 or KbCliX >= KbCw or KbCliY >= KbCh)
		{
		msgbox, 4144, DeepFish, That spot is outside the Roblox window, so it was not saved.`n`nThe game window is %KbCw% x %KbCh%, and you picked %KbCliX%`, %KbCliY% inside it.`n`nPut Roblox on the screen you macro on, open your inventory there, and pick the button on that same screen.
		Gui, Show
		TargetSection := "Keeper"
		gosub, ShowSection
		gosub, KeeperRefreshSpots
		return
		}
	if (KbPickWhat = "enchant")
		{
		KeeperEnchantX := KbCliX
		KeeperEnchantY := KbCliY
		}
	else
		{
		KeeperConfirmX := KbCliX
		KeeperConfirmY := KbCliY
		}
	gosub, QueueAutoSave
	}
Gui, Show
TargetSection := "Keeper"
gosub, ShowSection
gosub, KeeperRefreshSpots
return

KeeperAutoBarChanged:
GuiControlGet, KbAbV, 1:, KeeperAutoBar
if (!ErrorLevel)
	KeeperAutoBar := KbAbV ? true : false
gosub, QueueAutoSave
return

KeeperTestAuto:
gosub, KeeperFindRoblox
if (!RobloxHwnd)
	{
	msgbox, 4144, DeepFish, Could not find the Roblox window. Start Roblox first.
	return
	}
GuiControlGet, KbPctV, 1:, KeeperAutoPct
if (!ErrorLevel and KbPctV != "")
	KeeperAutoPct := KbPctV
Gui, Hide
WinActivate, ahk_id %RobloxHwnd%
WinWaitActive, ahk_id %RobloxHwnd%, , 2
Sleep 300
KbBarY := -1
KbTok := KbAutoReadStable(KbTp, 5)
Gui, Show
TargetSection := "Keeper"
gosub, ShowSection
if (!KbTok)
	msgbox, 4144, DeepFish, Could not find the power bar.`n`nHold your Keeperbound rod so the purple power bar (the one that says `% Power) is showing above your hotbar, close any menus, then press Test again.
else
	{
	KbTat := KeeperAutoPct
	if KbTat is not number
		KbTat := 15
	KbTres := (KbTp < KbTat) ? "This WOULD start a recharge." : "This would NOT start a recharge yet."
	msgbox, 4160, DeepFish, % "Found the power bar - it reads about " . Round(KbTp, 1) . "`%.`nIt recharges below " . KbTat . "`%.`n`n" . KbTres
	}
return

KeeperOcrChanged:
GuiControlGet, KbOcrV, 1:, KeeperOcrOn
if (!ErrorLevel)
	KeeperOcrOn := KbOcrV ? true : false
gosub, QueueAutoSave
return

KeeperFindRoblox:
if (!RobloxHwnd or !WinExist("ahk_id " . RobloxHwnd))
	{
	WinGet, RobloxHwnd, ID, ahk_exe RobloxPlayerBeta.exe
	if (!RobloxHwnd)
		WinGet, RobloxHwnd, ID, Roblox
	}
return

KeeperClearLine:
KeeperLineX := 0
KeeperLineY1 := 0
KeeperLineY2 := 0
gosub, KeeperRefreshSpots
gosub, QueueAutoSave
return

KeeperClearColor:
KeeperLineColor := -1
gosub, KeeperRefreshSpots
gosub, QueueAutoSave
return

KbLineNop:
return

KbLineKeyDown:
PickHeld[RegExReplace(A_ThisHotkey, "^\*")] := 1
return

KbLineKeyUp:
PickHeld[RegExReplace(A_ThisHotkey, "^\*|\s+up$")] := 0
return

; held = physical press, OR injected/remote input (RustDesk, Parsec, TeamViewer...), OR a key the
; power-line tool is swallowing with a hotkey. GetKeyState(k, "P") alone ignores remote-desktop input.
KeyHeld(k) {
	global PickHeld
	if (GetKeyState(k, "P") or GetKeyState(k))
		return true
	return (IsObject(PickHeld) and PickHeld[k])
}

KeeperSetLine:
gosub, KeeperFindRoblox
if (!RobloxHwnd)
	{
	msgbox, 4144, DeepFish, Could not find the Roblox window. Start Roblox first.
	return
	}
RobloxClientRect(RobloxHwnd, KbWx, KbWy, KbWw, KbWh)
Gui, Hide
WinActivate, ahk_id %RobloxHwnd%
Sleep 250
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
if (Abs(Round(KeeperLineY2) - Round(KeeperLineY1)) >= 2)
	{
	KbLx := KbWx + Round(KeeperLineX)
	KbLy1 := KbWy + Round(KeeperLineY1)
	KbLy2 := KbWy + Round(KeeperLineY2)
	}
else
	{
	MouseGetPos, KbMx, KbMy
	KbLx := KbMx
	KbLy1 := KbMy - 15
	KbLy2 := KbMy + 15
	}
KbLineKeys := ["Up", "Down", "Left", "Right", "Enter", "NumpadEnter", "Esc", "u", "LButton"]
PickHeld := {}
for i, kn in KbLineKeys
	{
	Hotkey, *%kn%, KbLineKeyDown, On
	Hotkey, *%kn% up, KbLineKeyUp, On
	}
Gui, KbLine:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
Gui, KbLine:Color, FF2D55
KbLineSave := false
KbLock := false
KbDrag := ""
KbUWas := false
KbTU := 0
KbTD := 0
KbTL := 0
KbTR := 0
VarSetCapacity(KbClip, 16, 0)
Loop
	{
	if KeyHeld("Esc")
		break
	if (KeyHeld("Enter") or KeyHeld("NumpadEnter"))
		{
		KbLineSave := true
		break
		}
	MouseGetPos, KbMx, KbMy
	KbUNow := KeyHeld("u")
	if (KbUNow and !KbUWas)
		{
		if (!KbLock)
			{
			KbLx := KbMx
			KbLy1 := KbMy
			KbLy2 := KbMy + 2
			NumPut(KbMx, KbClip, 0, "Int")
			NumPut(KbMy, KbClip, 4, "Int")
			NumPut(KbMx + 1, KbClip, 8, "Int")
			NumPut(KbWy + KbWh, KbClip, 12, "Int")
			DllCall("ClipCursor", "Ptr", &KbClip)
			KbLock := true
			}
		else
			{
			KbLy2 := (KbMy > KbLy1 + 2) ? KbMy : KbLy1 + 2
			DllCall("ClipCursor", "Ptr", 0)
			KbLock := false
			}
		}
	KbUWas := KbUNow
	if (KbLock)
		KbLy2 := (KbMy > KbLy1 + 2) ? KbMy : KbLy1 + 2
	KbLb := KeyHeld("LButton")
	if (KbLb and !KbLock)
		{
		if (KbDrag = "")
			{
			if (Abs(KbMx - KbLx) <= 8 and KbMy >= KbLy1 - 8 and KbMy <= KbLy2 + 8)
				{
				if (Abs(KbMy - KbLy1) <= 6)
					KbDrag := "top"
				else if (Abs(KbMy - KbLy2) <= 6)
					KbDrag := "bot"
				else
					{
					KbDrag := "move"
					KbOffX := KbMx - KbLx
					KbOffY := KbMy - KbLy1
					}
				}
			else
				KbDrag := "none"
			}
		if (KbDrag = "top")
			KbLy1 := (KbMy < KbLy2 - 2) ? KbMy : KbLy2 - 2
		else if (KbDrag = "bot")
			KbLy2 := (KbMy > KbLy1 + 2) ? KbMy : KbLy1 + 2
		else if (KbDrag = "move")
			{
			KbLen := KbLy2 - KbLy1
			KbLx := KbMx - KbOffX
			KbLy1 := KbMy - KbOffY
			KbLy2 := KbLy1 + KbLen
			}
		}
	else if (!KbLb)
		KbDrag := ""
	KbSt := KeyHeld("Shift") ? 10 : 1
	if (!KbLock)
		{
		if (KbKeyStep("Up", KbTU))
			{
			KbLy1 -= KbSt
			KbLy2 -= KbSt
			}
		if (KbKeyStep("Down", KbTD))
			{
			KbLy1 += KbSt
			KbLy2 += KbSt
			}
		if (KbKeyStep("Left", KbTL))
			KbLx -= KbSt
		if (KbKeyStep("Right", KbTR))
			KbLx += KbSt
		}
	KbLh := KbLy2 - KbLy1 + 1
	KbShowX := KbLx - 1
	Gui, KbLine:Show, x%KbShowX% y%KbLy1% w3 h%KbLh% NoActivate
	KbTipX := KbLx + 18
	if (KbLock)
		ToolTip, % "Move the mouse down to the BOTTOM of the bar`nand press U again (the cursor is locked to the line)", %KbTipX%, %KbLy1%, 20
	else
		ToolTip, % "Power line: " . KbLh . " px tall`nDrag the line to move it`nDrag its top or bottom end to make it taller / shorter`nU - press on the top of the bar, then U again on the bottom`nArrow keys - nudge it (Shift = 10 px)`nEnter - save     Esc - cancel", %KbTipX%, %KbLy1%, 20
	Sleep 15
	}
DllCall("ClipCursor", "Ptr", 0)
while (KeyHeld("Enter") or KeyHeld("NumpadEnter") or KeyHeld("Esc") or KeyHeld("LButton"))
	Sleep 20
for i, kn in KbLineKeys
	{
	Hotkey, *%kn%, KbLineKeyDown, Off
	Hotkey, *%kn% up, KbLineKeyUp, Off
	}
PickHeld := {}
Gui, KbLine:Destroy
ToolTip, , , , 20
CoordMode, Mouse, Client
CoordMode, ToolTip, Relative
if (KbLineSave)
	{
	KbCx := KbLx - KbWx
	KbCy1 := KbLy1 - KbWy
	KbCy2 := KbLy2 - KbWy
	if (KbCx < 0 or KbCy1 < 0 or KbCx >= KbWw or KbCy2 >= KbWh)
		msgbox, 4144, DeepFish, That line is outside the Roblox window, so it was not saved.
	else
		{
		KeeperLineX := KbCx
		KeeperLineY1 := KbCy1
		KeeperLineY2 := KbCy2
		gosub, QueueAutoSave
		}
	}
Gui, Show
TargetSection := "Keeper"
gosub, ShowSection
gosub, KeeperRefreshSpots
return

KeeperPickColor:
Gui, Hide
Sleep 250
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
KbPickCancel := false
KbPc := ""
Loop
	{
	if KeyHeld("Escape")
		{
		KbPickCancel := true
		break
		}
	if KeyHeld("u")
		{
		MouseGetPos, KbPx, KbPy
		PixelGetColor, KbPc, %KbPx%, %KbPy%, RGB
		while KeyHeld("u")
			Sleep 20
		break
		}
	MouseGetPos, KbMx, KbMy
	PixelGetColor, KbHov, %KbMx%, %KbMy%, RGB
	ToolTip, Press U over the FILLED part of the power bar (not the text)`nColor under the mouse: %KbHov%`nEsc to cancel, % KbMx + 26, % KbMy + 30, 20
	Sleep 30
	}
ToolTip, , , , 20
CoordMode, Mouse, Client
CoordMode, Pixel, Client
CoordMode, ToolTip, Relative
if (!KbPickCancel and KbPc != "")
	{
	KeeperLineColor := KbPc + 0
	gosub, QueueAutoSave
	}
Gui, Show
TargetSection := "Keeper"
gosub, ShowSection
gosub, KeeperRefreshSpots
return

KeeperTestLine:
gosub, KeeperFindRoblox
if (!RobloxHwnd)
	{
	msgbox, 4144, DeepFish, Could not find the Roblox window. Start Roblox first.
	return
	}
GuiControlGet, KbTolV, 1:, KeeperLineTol
if (!ErrorLevel and KbTolV != "")
	KeeperLineTol := KbTolV
Gui, Hide
WinActivate, ahk_id %RobloxHwnd%
WinWaitActive, ahk_id %RobloxHwnd%, , 2
Sleep 300
KbTr := KbLineCheck(KbTm, KbTt)
Gui, Show
TargetSection := "Keeper"
gosub, ShowSection
if (KbTr < 0)
	msgbox, 4144, DeepFish, Set the power line and pick the bar color first.
else
	{
	KbTn := KbLineNeed(KbTt)
	KbTres := (KbTr = 1) ? "This WOULD start a recharge (the bar has dropped below the line)." : "This would NOT start a recharge (the bar still covers the line)."
	msgbox, 4160, DeepFish, % KbTm . " of " . KbTt . " pixels on the line are not the bar color.`nIt recharges at " . KbTn . " or more.`n`n" . KbTres
	}
return

KeeperStatusTick:
if (KbBusy)
	KbLine := "Running now - " . KbStatus . "..."
else if (!KeeperAuto)
	KbLine := "Off."
else if (KeeperRelicKey = "")
	KbLine := "Set a relic hotbar key to enable."
else if (!MacroRunning)
	KbLine := "Waiting for the macro to start."
else if (KeeperAutoBar)
	{
	KbLine := "Recharges when the power bar reads under " . KeeperAutoPct . "`%."
	if (KbOcrLast != "")
		KbLine .= "   Last check: " . KbOcrLast
	}
else if (KeeperOcrOn)
	{
	KbLine := "Recharges when the power bar drops below the line."
	if (KbOcrLast != "")
		KbLine .= "   Last check: " . KbOcrLast
	}
else
	{
	KbLeft := Round(KeeperEveryCatches) - KbCatches
	if (KbLeft < 0)
		KbLeft := 0
	KbLine := KbLeft . " more catches until the next recharge."
	}
if (KbLastResult != "")
	KbLine .= "   Last: " . KbLastResult . "."
GuiControl, 1:, KbStatLine, %KbLine%
return

;====================================================================================================;

BuildAquariumSection:

Gui, Font, s9 Norm c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w220 h18 +0x100 gUtilBack HwndhC, ‹  Fishing Add-ons
AquariumCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorAccentBGR}

hC := AddPanel(CARDX, 140, CARDW, 54)
AquariumCtrls.Push(hC)
Gui, Font, s11 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y157 w220 h20 HwndhC, Auto Aquarium
AquariumCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
AQchk := AquariumAuto ? "Checked" : ""
Gui, Add, CheckBox, x572 y157 w58 h20 c%ColorText% vAquariumAuto %AQchk% gAquariumAutoChanged HwndhC, On
AquariumCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x642 y153 w86 h28 Center +0x100 +0x200 gUtilBack HwndhC, Hide
AquariumCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 86, 28, 7)

hC := AddPanel(CARDX, 204, CARDW, 222)
AquariumCtrls.Push(hC)
AquariumBodyCtrls.Push(hC)

AqFieldDefs := [ ["Run every (minutes)","AquariumEveryMin"
	, "How long to fish between aquarium trips.`n`nFish food lasts one hour, so 60 keeps it`nalways active."]
	, ["Cards per trip","AquariumFoodCount"
	, "A safety cap on how many cards it will press`nin one trip.`n`nThe row holds your owned foods first and then`nthe shop, so there are more cards than there`nare foods - the sweep stops on its own at the`nend of the row.`n`nAnything under 10 is treated as 10, or it`nwould cut the trip short."]
	, ["Buy limit per trip","AquariumMaxBuys"
	, "The most Buy buttons it will press in one trip.`n`nEvery card gets pressed once, so leave this`nabove the number of foods on sale - it is only`nhere to stop a runaway from spending.`n`nA sold-out card looks exactly like a Buy one`nand costs nothing to press."]
	, ["Step delay (ms)","AquariumStepDelay"
	, "Pause after each click, to let the button`nchange from Buy to Use."]
	, ["Menu delay (ms)","AquariumOpenDelay"
	, "Pause after opening or closing the Aquariums`nmenu. Raise it if the panel is slow to appear."]
	, ["Scroll sweep (notches)","AquariumScrollSteps"
	, "Wheel notches per nudge when winding the row`nback to the start.`n`nIt keeps nudging until the row stops moving,`nso this is just the step size."] ]

AqY := 220
Gui, Font, s9 Norm c%ColorText%, Segoe UI
for i, d in AqFieldDefs
	{
	lbl := d[1]
	var := d[2]
	hint := d[3]
	Gui, Add, Text, x%CX% y%AqY% w%LW% h20 HwndhAC, %lbl%:
	AquariumCtrls.Push(hAC)
	AquariumBodyCtrls.Push(hAC)
	SpecialBrushes[hAC] := {brush: hBrushCard, text: ColorTextBGR}
	EdOpt := TmNumOpt(var)
	Gui, Add, Edit, x%IX% y%AqY% w%IW% h20 v%var% gQueueAutoSave HwndhAC %EdOpt%, % %var%
	AquariumCtrls.Push(hAC)
	AquariumBodyCtrls.Push(hAC)
	ThemedCtrls.Push(hAC)
	Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
	Gui, Add, Text, x%QX% y%AqY% w16 h20 Center +0x100 +0x200 HwndhAQ, ?
	Gui, Font, s9 Norm c%ColorText%, Segoe UI
	AquariumCtrls.Push(hAQ)
	AquariumBodyCtrls.Push(hAQ)
	SpecialBrushes[hAQ] := {brush: hBrushCard, text: ColorAccentBGR}
	IconTips[hAQ] := hint
	AqY += 26
	}

Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
AqStatY := AqY + 8
Gui, Add, Text, x%CX% y%AqStatY% w520 h20 vAqStatLine HwndhAC, Idle.
AquariumCtrls.Push(hAC)
AquariumBodyCtrls.Push(hAC)
SpecialBrushes[hAC] := {brush: hBrushCard, text: ColorMutedBGR}

AqNoteY := 436
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CARDX% y%AqNoteY% w%CARDW% h62 HwndhAC, Presses Aquariums at the top of the screen`, buys each fish food and uses it`, then closes the menu and carries on fishing.`nIt only runs between casts`, never during a minigame.`nCamera mode is forced off while this is on - it hides the Aquariums button.
AquariumCtrls.Push(hAC)
SpecialBrushes[hAC] := {brush: hBrushBG, text: ColorMutedBGR}
Gui, Font, s9 c%ColorMuted%, Segoe UI

return

AquariumAutoChanged:
GuiControlGet, AquariumAuto, 1:, AquariumAuto
GuiControl, 1:, UtilAquariumOn, % (AquariumAuto ? 1 : 0)
gosub, RefreshCameraLock
gosub, ShowSection
gosub, QueueAutoSave
return

AquariumStatusTick:
if (AqBusy)
	AqLine := "Running now - " . AqStatus . "..."
else if (!AquariumAuto)
	AqLine := "Off."
else if (!MacroRunning)
	AqLine := "Waiting for the macro to start."
else if (AqNextTick = 0)
	AqLine := "Next trip: on the next cast."
else
	{
	AqLeft := (AqNextTick - A_TickCount) // 1000
	if (AqLeft < 0)
		AqLeft := 0
	AqLine := "Next trip in " . (AqLeft // 60) . "m " . Mod(AqLeft, 60) . "s."
	}
if (AqLastResult != "")
	AqLine .= "   Last trip: " . AqLastResult . "."
GuiControl, 1:, AqStatLine, %AqLine%
return

;====================================================================================================;

BuildMiscSection:

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w300 h16 HwndhC, MISCELLANEOUS
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}

hC := AddPanel(CARDX, 140, CARDW, 54)
MiscCtrls.Push(hC)
Gui, Font, s11 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y157 w300 h20 HwndhC, Pogo Jump Tech
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
PjChk := PogoOn ? "Checked" : ""
Gui, Add, CheckBox, x572 y157 w58 h20 c%ColorText% vPogoOn %PjChk% gPogoOnChanged HwndhC, On
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x642 y153 w86 h28 Center +0x100 +0x200 gPogoTry HwndhC, ▶ Try
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 86, 28, 7)
IconTips[hC] := "Switches to Roblox and does the jump once"

hC := AddPanel(CARDX, 204, CARDW, 296)
MiscCtrls.Push(hC)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y214 w%TXW% h34 HwndhC, Press the hotkey in Roblox and it does, top to bottom: pogo stick, wait, jump coil, jump.`nKeys: a number or letter, or a key name like Space, Numpad9 or LShift.
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}

PjY := 256
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y%PjY% w%LW% h20 HwndhC, Hotkey:
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Add, Edit, x%IX% y%PjY% w120 h20 vPogoHotkeyCtrl gQueueAutoSave HwndhC, %PogoHotkey%
MiscCtrls.Push(hC)
ThemedCtrls.Push(hC)
IconTips[hC] := "The key or mouse button that starts the Pogo Jump Tech.`nPress Set, then the key or mouse button you want - or type it:`nXButton1 = mouse back side button, XButton2 = front side button,`nMButton = middle button. Add ^ ! + for Ctrl Alt Shift (^XButton1).`nIt only works while Roblox is the active window."
PjSx := IX + 128
PjSy := PjY - 2
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%PjSx% y%PjSy% w72 h24 Center +0x100 +0x200 vPogoSetBtn gPogoSetKey HwndhC, Set
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBorder, text: ColorAccentBGR}
RoundCtrl(hC, 72, 24, 7)
IconTips[hC] := "Press this, then the key or mouse button you want (Esc cancels)"
Gui, Font, s9 Norm c%ColorText%, Segoe UI
PjY += 34

for i, d in [ ["1.  Pogo stick key","PogoKey",""], ["2.  Wait (ms)","PogoWait","num"], ["3.  Jump coil key","PogoCoilKey",""]
	, ["     Wait before jumping (ms)","PogoCoilWait","num"], ["4.  Jump key","PogoJumpKey",""], ["Key hold (ms)","PogoHold","num"] ]
	{
	PjLbl := d[1]
	PjVar := d[2]
	PjOpt := (d[3] = "num") ? "+Number" : ""
	PjVal := %PjVar%
	Gui, Add, Text, x%CX% y%PjY% w%LW% h20 HwndhC, %PjLbl%:
	MiscCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
	Gui, Add, Edit, x%IX% y%PjY% w90 h20 v%PjVar% gQueueAutoSave %PjOpt% HwndhC, %PjVal%
	MiscCtrls.Push(hC)
	ThemedCtrls.Push(hC)
	PjY += 28
	if (i = 5)
		PjY += 6
	}
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y%PjY% w%TXW% h18 vPogoStatus HwndhC, % PogoStatusText()
MiscCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
return

PogoOnChanged:
GuiControlGet, PogoOn, 1:, PogoOn
PogoOn := PogoOn ? true : false
gosub, PogoApplyHotkey
gosub, QueueAutoSave
return

; (re)arms the Pogo Jump Tech hotkey - only while Roblox is the active window
PogoApplyHotkey:
Hotkey, IfWinActive, ahk_group RobloxGrp
if (PogoHkNow != "")
	Hotkey, % "$" . PogoHkNow, PogoRun, Off UseErrorLevel
PogoHkNow := ""
if (PogoOn and PogoHotkey != "")
	{
	Hotkey, % "$" . PogoHotkey, PogoRun, On UseErrorLevel
	if (!ErrorLevel)
		PogoHkNow := PogoHotkey
	}
Hotkey, IfWinActive
GuiControl, 1:, PogoStatus, % PogoStatusText()
return

PogoStatusText() {
	global PogoOn, PogoHkNow, PogoHotkey
	if (!PogoOn)
		return "Off - tick On to use it."
	if (PogoHkNow = "")
		return "That hotkey cannot be used - press Set and pick another one."
	return "Ready - press " . PogoHkNow . PogoKeyNice(PogoHkNow) . " in Roblox."
}

PogoKeyNice(k) {
	k := RegExReplace(k, "^[\^!+#]+")
	return {XButton1: " (mouse back side button)", XButton2: " (mouse front side button)", MButton: " (middle mouse button)", RButton: " (right mouse button)"}[k]
}

; Set: the next key or mouse button pressed becomes the hotkey (Esc cancels)
PogoSetKey:
if (PogoCapturing)
	return
PogoCapturing := true
; the old hotkey must not fire (or swallow the press) while choosing
Hotkey, IfWinActive, ahk_group RobloxGrp
if (PogoHkNow != "")
	Hotkey, % "$" . PogoHkNow, PogoRun, Off UseErrorLevel
Hotkey, IfWinActive
PogoHkNow := ""
GuiControl, 1:, PogoSetBtn, ...
GuiControl, 1:, PogoStatus, Press the key or mouse button you want - Esc cancels.
; a key pressed now also types into the box that has focus - make that the hotkey box, it is overwritten after
GuiControl, 1:Focus, PogoHotkeyCtrl
PogoNew := PogoCapture()
GuiControl, 1:, PogoSetBtn, Set
if (PogoNew != "")
	{
	PogoHotkey := PogoNew
	GuiControl, 1:, PogoHotkeyCtrl, %PogoNew%
	gosub, QueueAutoSave
	}
gosub, PogoApplyHotkey
PogoCapturing := false
return

; waits up to 10 s for a key or mouse button (left click excluded) and returns its hotkey name with
; ^ ! + # for any Ctrl Alt Shift Win held with it, "" on Esc or time-out
PogoCapture() {
	; the click on Set is still down
	KeyWait, LButton
	t0 := A_TickCount
	while (A_TickCount - t0 < 10000)
		{
		if (GetKeyState("Escape", "P"))
			{
			KeyWait, Escape
			return ""
			}
		vk := 2
		while (vk <= 0xFE)
			{
			; skip Esc, and Ctrl Alt Shift Win themselves - those only count held with another key
			if (vk = 0x1B or vk = 0x10 or vk = 0x11 or vk = 0x12 or (vk >= 0xA0 and vk <= 0xA5) or vk = 0x5B or vk = 0x5C)
				{
				vk++
				continue
				}
			kv := "vk" . Format("{:02X}", vk)
			if (GetKeyState(kv, "P") or GetKeyState(kv))
				{
				name := GetKeyName(kv)
				if (name != "")
					{
					pre := (GetKeyState("Ctrl") ? "^" : "") . (GetKeyState("Alt") ? "!" : "") . (GetKeyState("Shift") ? "+" : "") . ((GetKeyState("LWin") or GetKeyState("RWin")) ? "#" : "")
					; let go first, so it does not fire the moment it is set
					KeyWait, %name%
					return pre . name
					}
				}
			vk++
			}
		Sleep, 15
		}
	return ""
}

PogoTry:
gosub, ResolveRoblox
if (!RobloxHwnd)
	{
	msgbox, 4144, DeepFish, Could not find the Roblox window. Start Roblox first.
	return
	}
WinActivate, ahk_id %RobloxHwnd%
WinWaitActive, ahk_id %RobloxHwnd%, , 2
Sleep, 300
gosub, PogoRun
return

PogoRun:
if (PogoBusy)
	return
PogoBusy := true
PogoPress(PogoKey)
PreciseSleep(PogoNum(PogoWait, 600))
PogoPress(PogoCoilKey)
PreciseSleep(PogoNum(PogoCoilWait, 0))
PogoPress(PogoJumpKey)
PogoBusy := false
return

PogoNum(v, def) {
	if v is not number
		return def
	return (v < 0) ? 0 : v
}

; one key: down, hold, up. A key name that Windows does not know is skipped.
PogoPress(k) {
	global PogoHold
	k := Trim(k)
	if (k = "" or (!GetKeyVK(k) and !GetKeySC(k)))
		return
	Send, {%k% down}
	PreciseSleep(PogoNum(PogoHold, 30))
	Send, {%k% up}
}

BuildTotemSection:

Gui, Font, s9 Norm c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w220 h18 +0x100 gUtilBack HwndhC, ‹  Fishing Add-ons
TotemCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorAccentBGR}

hC := AddPanel(CARDX, 140, CARDW, 54)
TotemCtrls.Push(hC)
Gui, Font, s11 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y157 w220 h20 HwndhC, Auto Totem
TotemCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
TAchk := TotemAuto ? "Checked" : ""
Gui, Add, CheckBox, x572 y157 w58 h20 c%ColorText% vTotemAuto %TAchk% gTotemAutoChanged HwndhC, On
TotemCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x642 y153 w86 h28 Center +0x100 +0x200 gUtilBack HwndhC, Hide
TotemCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 86, 28, 7)

; ---- body ----
hC := AddPanel(CARDX, 204, CARDW, 176)
TotemCtrls.Push(hC)
TotemBodyCtrls.Push(hC)

Gui, Font, s9 c%ColorText%, Segoe UI
TGchk := TotemGlobal ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y216 w400 h20 c%ColorText% vTotemGlobal %TGchk% gTotemGlobalChanged HwndhTC, Share Totem settings across all profiles
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
SpecialBrushes[hTC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%QX% y216 w16 h20 Center +0x100 +0x200 HwndhTC, ?
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
IconTips[hTC] := "ON  - one set of Totem settings shared by every`n      profile, stored in Settings.ini.`nOFF - each profile keeps its own."
Gui, Font, s9 Norm c%ColorText%, Segoe UI

TotemOptList := "None|Day|Night|Clearcast|Aurora|Starfall|Eclipse|Tempest|Windset|Smokescreen|Shiny|Sparkling|Mutation"

Gui, Add, Text, x%CX% y244 w160 h20 HwndhTC, Target Event 1:
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
Gui, Add, DropDownList, x%IX% y242 w%IW% h240 vTotemSel1 gTotemSelChanged HwndhTC, %TotemOptList%
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
ThemedCtrls.Push(hTC)
GuiControl, 1:ChooseString, TotemSel1, %TotemSel1%

Gui, Add, Text, x%CX% y272 w160 h20 HwndhTC, Target Event 2:
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
Gui, Add, DropDownList, x%IX% y270 w%IW% h240 vTotemSel2 gTotemSelChanged HwndhTC, %TotemOptList%
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
ThemedCtrls.Push(hTC)
GuiControl, 1:ChooseString, TotemSel2, %TotemSel2%

Gui, Add, Text, x%CX% y300 w160 h20 HwndhTC, Target Event 3:
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
Gui, Add, DropDownList, x%IX% y298 w%IW% h240 vTotemSel3 gTotemSelChanged HwndhTC, %TotemOptList%
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
ThemedCtrls.Push(hTC)
GuiControl, 1:ChooseString, TotemSel3, %TotemSel3%

Gui, Add, Text, x%CX% y330 w130 h20 HwndhTC, Check every (s):
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
Gui, Add, Edit, x338 y328 w60 h20 vTotemPollSec gQueueAutoSave HwndhTC +Number, % TotemPollSec
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
ThemedCtrls.Push(hTC)
Gui, Add, Text, x420 y330 w110 h20 HwndhTC, Pop delay (ms):
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
Gui, Add, Edit, x536 y328 w60 h20 vTotemActDelay gQueueAutoSave HwndhTC, % TotemActDelay
TotemCtrls.Push(hTC)
TotemBodyCtrls.Push(hTC)
ThemedCtrls.Push(hTC)

; ---- hotbar keys ----
hC := AddPanel(CARDX, 390, CARDW, 162)
TotemCtrls.Push(hC)
TotemBodyCtrls.Push(hC)

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y400 w%TXW% h16 HwndhTotemKeyHdr, HOTBAR KEYS
TotemCtrls.Push(hTotemKeyHdr)
TotemBodyCtrls.Push(hTotemKeyHdr)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
TotemKeyTop := 422

TotemRowNames := ["Sundial","Clearcast","Tempest","Windset","Smokescreen","Eclipse","Aurora","Starfall","Shiny","Sparkling","Mutation"]
TotemRowLabel := {Sundial: "Sundial (day/night)", Clearcast: "Clearcast (clears weather)"
	, Tempest: "Tempest (Rain)", Windset: "Windset (Windy)", Smokescreen: "Smokescreen (Foggy)"
	, Eclipse: "Eclipse", Aurora: "Aurora", Starfall: "Starfall"
	, Shiny: "Shiny", Sparkling: "Sparkling", Mutation: "Mutation"}
TotemLblH := {}
TotemEdtH := {}

for i, nm in TotemRowNames
	{
	kvar := "TotemKey" . nm
	lt := TotemRowLabel[nm]
	Gui, Add, Text, x%CX% y%TotemKeyTop% w260 h20 HwndhTL, %lt%
	TotemCtrls.Push(hTL)
	TotemBodyCtrls.Push(hTL)
	SpecialBrushes[hTL] := {brush: hBrushCard, text: ColorWhiteBGR}
	TotemLblH[nm] := hTL
	Gui, Add, Edit, x%IX% y%TotemKeyTop% w70 h20 v%kvar% gQueueAutoSave HwndhTE Limit6, % %kvar%
	TotemCtrls.Push(hTE)
	TotemBodyCtrls.Push(hTE)
	ThemedCtrls.Push(hTE)
	TotemEdtH[nm] := hTE
	}

; ---- status ----
hC := AddPanel(CARDX, 562, CARDW, 96)
TotemCtrls.Push(hC)
TotemBodyCtrls.Push(hC)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y572 w%TXW% h16 HwndhC, STATUS
TotemCtrls.Push(hC)
TotemBodyCtrls.Push(hC)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
Gui, Add, Text, x%CX% y592 w%TXW% h36 vTotemStatusText HwndhC, ---
TotemCtrls.Push(hC)
TotemBodyCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}
Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y630 w%TXW% h28 HwndhTotemNote, Private servers only - totems cannot be used in public ones.`nCamera mode hides the weather icons, so it stays off while Auto Totem is on.
TotemCtrls.Push(hTotemNote)
TotemBodyCtrls.Push(hTotemNote)
SpecialBrushes[hTotemNote] := {brush: hBrushCard, text: ColorMutedBGR}
Gui, Font, s9 c%ColorMuted%, Segoe UI
TotemSelSanitize()
TotemListsRefresh()

return

;====================================================================================================;

TotemStatusTick:
if (TargetSection != "Totem")
	{
	SetTimer, TotemStatusTick, Off
	return
	}
if (!TotemAuto)
	TotemStat := "Auto Totem is off."
else if (TotemTime = "" and TotemWeather = "")
	TotemStat := "Waiting for the first check..."
else
	{
	TotemStat := "Time: " . (TotemTime = "" ? "?" : TotemTime)
	TotemStat .= "     Weather: " . (TotemWeather = "" ? "?" : TotemWeather)
	if (TotemEvents != "")
		TotemStat .= "     " . StrReplace(TotemEvents, "?", "unknown")
	TotemStat2 := TotemAssumeText()
	if (TotemStat2 != "")
		TotemStat2 := "Unknown icon = " . TotemStat2
	ct := TotemCoolText()
	if (ct != "")
		TotemStat2 .= (TotemStat2 = "" ? "" : "     ") . ct
	if (TotemStat2 != "")
		TotemStat .= "`n" . TotemStat2
	}
GuiControl, 1:, TotemStatusText, %TotemStat%
return

;====================================================================================================;

RefreshTotemKeys:
if (!TotemLblH)
	return
TotemNeed := {}
TotemNeedList := []
for i, sel in [TotemSel1, TotemSel2, TotemSel3]
	{
	if (sel = "" or sel = "None")
		continue
	if (sel = "Day" or sel = "Night")
		{
		TotemNeed["Sundial"] := 1
		continue
		}
	if (!TotemNeed.HasKey(sel))
		{
		TotemNeed[sel] := 1
		TotemNeedList.Push(sel)
		}
	if (sel = "Aurora" or sel = "Starfall" or sel = "Eclipse")
		TotemNeed["Sundial"] := 1
	}
TotemOrder := []
if (TotemNeed.HasKey("Sundial"))
	TotemOrder.Push("Sundial")
if (TotemNeed.HasKey("Clearcast"))
	TotemOrder.Push("Clearcast")
for i, nm in TotemNeedList
	{
	if (nm = "Sundial" or nm = "Clearcast")
		continue
	TotemOrder.Push(nm)
	}
RowY := TotemKeyTop
for i, nm in TotemRowNames
	{
	GuiControl, 1:Hide, % TotemLblH[nm]
	GuiControl, 1:Hide, % TotemEdtH[nm]
	}
for i, nm in TotemOrder
	{
	hL := TotemLblH[nm]
	hE := TotemEdtH[nm]
	SetBase(hL, CX, RowY)
	SetBase(hE, IX, RowY)
	if (TargetSection = "Totem" and TotemAuto)
		{
		GuiControl, 1:Show, %hL%
		GuiControl, 1:Show, %hE%
		}
	RowY += 24
	}
return

;====================================================================================================;

TotemSelChanged:
GuiControlGet, TotemSel1, 1:, TotemSel1
GuiControlGet, TotemSel2, 1:, TotemSel2
GuiControlGet, TotemSel3, 1:, TotemSel3
TotemSelSanitize()
TotemListsRefresh()
gosub, ShowSection
gosub, QueueAutoSave
return

;====================================================================================================;

TotemGlobalChanged:
GuiControlGet, TotemGlobal, 1:, TotemGlobal
TGval := TotemGlobal ? 1 : 0
IniWrite, %TGval%, %SettingsFile%, Totem, Global
gosub, QueueAutoSave
return

;====================================================================================================;

TotemAutoChanged:
GuiControlGet, TotemAuto, 1:, TotemAuto
GuiControl, 1:, UtilTotemOn, % (TotemAuto ? 1 : 0)
gosub, RefreshCameraLock
gosub, ShowSection
gosub, QueueAutoSave
return

;====================================================================================================;

RefreshCameraLock:
if (TotemAuto or AquariumAuto or KeeperAuto)
	{
	GuiControl, 1:Disable, AutoEnableCameraMode
	GuiControl, 1:Disable, AutoCameraDelay
	}
else
	{
	GuiControl, 1:Enable, AutoEnableCameraMode
	GuiControl, 1:Enable, AutoCameraDelay
	}
return

;====================================================================================================;

BuildWebhookSection:

Gui, Font, s9 Norm c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w220 h18 +0x100 gUtilBack HwndhWC, ‹  Fishing Add-ons
WebhookCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushBG, text: ColorAccentBGR}

hC := AddPanel(CARDX, 140, CARDW, 54)
WebhookCtrls.Push(hC)
Gui, Font, s11 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CX% y157 w240 h20 HwndhWC, Discord Webhook
WebhookCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
WEchk := WebhookOn ? "Checked" : ""
Gui, Add, CheckBox, x572 y157 w58 h20 c%ColorText% vWebhookOn gWebhookOnChanged %WEchk% HwndhWC, On
WebhookCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x642 y153 w86 h28 Center +0x100 +0x200 gUtilBack HwndhWC, Hide
WebhookCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hWC, 86, 28, 7)
Gui, Font, s9 Norm c%ColorText%, Segoe UI

hC := AddPanel(CARDX, 204, CARDW, 62)
WebhookCtrls.Push(hC)
WebhookBodyCtrls.Push(hC)
Gui, Add, Text, x%CX% y218 w160 h20 HwndhWC, Webhook URL:
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Add, Edit, x%CX% y238 w%TXW% h20 vWebhookURL gQueueAutoSave HwndhWC, % WebhookURL
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
ThemedCtrls.Push(hWC)

hC := AddPanel(CARDX, 276, CARDW, 226)
WebhookCtrls.Push(hC)
WebhookBodyCtrls.Push(hC)

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y286 w%TXW% h16 HwndhWC, NOTIFICATIONS
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
Gui, Font, s9 Norm c%ColorText%, Segoe UI

Gui, Add, Text, x%CX% y310 w240 h20 HwndhWC, Status report every (min):
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Add, Edit, x%IX% y310 w70 h20 vWebhookSummaryMin gQueueAutoSave HwndhWC +Number, % WebhookSummaryMin
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
ThemedCtrls.Push(hWC)

Gui, Add, Text, x%CX% y336 w240 h20 HwndhWC, Alert if no catch for (min):
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Add, Edit, x%IX% y336 w70 h20 vWebhookStallMin gQueueAutoSave HwndhWC +Number, % WebhookStallMin
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
ThemedCtrls.Push(hWC)

WAchk := WebhookOnAlert ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y368 w%TXW% h20 c%ColorText% vWebhookOnAlert gQueueAutoSave %WAchk% HwndhWC, Send alerts (stopped, stalled, re-equip)
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}

WCchk := WebhookOnCatch ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y392 w%TXW% h20 c%ColorText% vWebhookOnCatch gQueueAutoSave %WCchk% HwndhWC, Send a message for every catch
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}

WSchk := WebhookShot ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y416 w%TXW% h20 c%ColorText% vWebhookShot gQueueAutoSave %WSchk% HwndhWC, Attach a screenshot to status reports
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorTextBGR}

Gui, Font, s8 c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y440 w%TXW% h28 HwndhWC, Captures the whole screen. It shows your username, level`nand cash, and is deleted right after it is sent.
WebhookCtrls.Push(hWC)
WebhookBodyCtrls.Push(hWC)
SpecialBrushes[hWC] := {brush: hBrushCard, text: ColorMutedBGR}

Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Button, x%CX% y470 w170 h26 gWebhookTest HwndhWebhookTestBtn, Send test message
WebhookCtrls.Push(hWebhookTestBtn)
WebhookBodyCtrls.Push(hWebhookTestBtn)
ThemedCtrls.Push(hWebhookTestBtn)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
return

;====================================================================================================;

WebhookOnChanged:
GuiControlGet, WebhookOn, 1:, WebhookOn
GuiControl, 1:, UtilWebhookOn, % (WebhookOn ? 1 : 0)
gosub, ShowSection
gosub, QueueAutoSave
return

;====================================================================================================;

WebhookTest:
GuiControlGet, WebhookURL, 1:, WebhookURL
if (WebhookURL = "")
	{
	msgbox, 4144, DeepFish, Enter a webhook URL first.
	return
	}
WhF := WhField("Status", "Test message", true)
WhF .= "," . WhField("Runtime", "0h 0m", true)
WhJ := WhBuildJson("DeepFish connected", "If you can read this, the webhook is working.", 3066993, WhF, "DeepFish")
if (WhPost(WhJ))
	msgbox, 4160, DeepFish, Test message sent.
else
	msgbox, 4144, DeepFish, Could not send. Check the URL is a full Discord webhook link and that you are online.
return

;====================================================================================================;

BuildFaqSection:

Gui, Font, s13 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w%CARDW% h28 HwndhFaqHdr, Frequently Asked Questions
FaqCtrls.Push(hFaqHdr)

FaqTexts := []
FaqNames := ["General", "Cast", "Shake", "Minigame", "Special Rods", "Utilities"]
FaqT := ""
FaqT .= "Problems you can hit before the macro even starts fishing, in the order you usually hit them.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "1.  THE MACRO DOES NOTHING AT ALL`n`n"
FaqT .= "Right-click the DeepFish file and choose Run as administrator.`n`n"
FaqT .= "If Roblox, or anything else on your PC, is running with more permission than the macro, Windows quietly throws away every click and key press the macro sends. Nothing looks broken, the game just ignores it. Try this before you change any setting.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "2.  COULD NOT FIND THE ROBLOX GAME WINDOW`n`n"
FaqT .= "Open Roblox and join a game before you press Start.`n`n"
FaqT .= "If Roblox is already open, close it fully and open it again. The macro looks for the Roblox player window, so a Roblox page open in your browser does not count.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "3.  I PRESS START BUT IT DOES NOT FISH`n`n"
FaqT .= "The Start button does not start fishing by itself. It finds Roblox, brings it to the front, maximizes it and turns your Start/Stop key on. Press your Start/Stop key after that to begin.`n`n"
FaqT .= "If the DeepFish window disappears when you press Start, that is normal. Tick Always open after pressing Start in General if you would rather keep it on screen.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "4.  MY START, RELOAD OR EXIT KEY DOES NOTHING`n`n"
FaqT .= "Check the Start/Stop key, Reload key and Exit key in General match the keys you are pressing.`n`n"
FaqT .= "Programs like Discord, OBS, Nvidia or keyboard software can grab a key before the macro sees it. Pick a key nothing else uses, such as F6.`n`n"
FaqT .= "These keys work anywhere on your PC while the macro is armed, so avoid keys you type in chat.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "5.  THE COLOR PICKER OR DETECTION LANDS IN THE WRONG PLACE`n`n"
FaqT .= "Run Roblox in fullscreen. If that does not fix it, set Windows display scale to 100% (Settings > System > Display > Scale) and restart your PC.`n`n"
FaqT .= "Windows scaling above 100% makes the macro look at the wrong part of the screen, so colors get picked from the wrong spot and nothing is ever detected. If true fullscreen breaks detection on your PC, use windowed fullscreen instead.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "6.  IT BROKE AFTER I RESIZED OR MOVED ROBLOX`n`n"
FaqT .= "Stop the macro and start it again.`n`n"
FaqT .= "The macro measures the Roblox window when it starts. Switching fullscreen on or off, resizing the window or dragging it to another monitor while it is running leaves it looking at the old spot.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "7.  THE CAMERA SETUP STEPS MESS THINGS UP`n`n"
FaqT .= "Untick the Auto options you do not want in General > Automatic game setup, or raise the delay ms next to the step that fails.`n`n"
FaqT .= "Each step (lower graphics, zoom, camera mode, look down, blur) presses keys and moves the camera for you. On a slow PC the game may not keep up, and a bigger delay gives it time.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "8.  AUTO-ENABLE CAMERA MODE IS GREYED OUT`n`n"
FaqT .= "That is on purpose. It is locked off while Auto Totem, Auto Aquarium or Auto Keeperbound is turned on, because camera mode hides the game interface those features need to read.`n`n"
FaqT .= "With camera mode off, the rod is equipped with your Rod hotbar slot key, so make sure that key is set in General > Recovery.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "9.  THE MACRO FISHES WITHOUT A ROD IN MY HAND`n`n"
FaqT .= "Set Rod hotbar slot key in General > Recovery to the number your rod sits on.`n`n"
FaqT .= "When camera mode is off, that key is the only way the macro equips your rod.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "10.  MY SETTINGS KEEP RESETTING`n`n"
FaqT .= "Press Save, or tick Auto-save so every change is saved the moment you make it.`n`n"
FaqT .= "Settings are stored per profile, so also check the profile at the top of the window is the one you think you are on. Auto Aquarium and Auto Keeperbound settings are shared by every profile, and Auto Totem can be shared with Share Totem settings across all profiles.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "11.  A POPUP SAYS SOME SETTINGS WERE INVALID AND WERE RESET`n`n"
FaqT .= "A value in that profile file could not be read, so the macro put that one setting back to its default. The popup lists which ones. Set them again and press Save.`n`n"
FaqT .= "This usually happens after editing a profile file by hand.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "12.  A POPUP SAYS A FIELD CONTAINS AN INVALID NUMBER`n`n"
FaqT .= "One of the boxes has letters, spaces or symbols where only a number belongs. The popup lists which field. Fix it and save again. Nothing in that field was saved until you do.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "13.  I CANNOT NAME OR DELETE A PROFILE`n`n"
FaqT .= "Profile names cannot contain these characters: \ / : * ? < > | or double quotes.`n`n"
FaqT .= "The Default profile cannot be deleted, and neither can your only profile. Make another profile first.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "14.  THE DEEPFISH WINDOW COVERS THE GAME`n`n"
FaqT .= "Untick Window always on top in General.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "15.  MY GAME LAGS WHILE THE MACRO RUNS`n`n"
FaqT .= "Tick Auto-lower graphics in General, and close other heavy programs.`n`n"
FaqT .= "The macro reads the screen many times a second. A low frame rate in Roblox makes the minigame harder to follow, so lower graphics directly helps tracking.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "16.  I NEED HELP WITH SOMETHING NOT LISTED HERE`n`n"
FaqT .= "Ask in the Discord (link in About). Say which rod you are using, your screen resolution, and include a screenshot or short video of the problem.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqTexts.Push(FaqT)
FaqT := ""
FaqT .= "Problems with getting the rod into the water.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "1.  THE MACRO NEVER CASTS`n`n"
FaqT .= "Make sure your rod is in your hand. Set Rod hotbar slot key in General > Recovery so the macro can equip it itself.`n`n"
FaqT .= "Also check nothing is open on screen, such as your inventory, a shop or a dialog box. The cast click lands on that instead.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "2.  MY CASTS ARE TOO SHORT OR TOO FAR`n`n"
FaqT .= "Normal cast: change Hold rod cast duration (ms) in Cast. Higher casts further out, lower casts closer in.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "3.  IT STARTS SHAKING BEFORE THE BOBBER LANDS`n`n"
FaqT .= "Raise Wait for bobber delay (ms) in Cast. Laggy servers need a bigger delay.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "4.  PERFECT CAST NEVER LETS GO`n`n"
FaqT .= "Open the Color Manager (F9) and pick the green and white colors of the cast power bar again, or raise Green tolerance and White tolerance a little.`n`n"
FaqT .= "If the bar is never found it gives up after Fail timeout (s) and lets go anyway, so it will not hang forever.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "5.  PERFECT CAST LETS GO TOO EARLY OR TOO LATE`n`n"
FaqT .= "Change Release timing in Cast in steps of 0.5. Lower it if it lets go too late, raise it if it lets go too early.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "6.  PERFECT CAST LETS GO AT RANDOM MOMENTS`n`n"
FaqT .= "Lower Green tolerance and White tolerance. When they are too high, other white or green parts of the screen get mistaken for the cast bar.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "7.  MY ROD OR BOBBER GETS STUCK ON THE GROUND`n`n"
FaqT .= "Set Re-equip after N failed casts in General to 2, and fill in Rod hotbar slot key and Equipment bag key.`n`n"
FaqT .= "After that many failed casts the macro swaps to your equipment bag and back to the rod, which drops the stuck bobber. If you leave Equipment bag key blank it presses the rod key twice instead.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "8.  IT CASTS AGAIN BEFORE THE CATCH ANIMATION FINISHES`n`n"
FaqT .= "Raise Restart delay (ms) in General. Try 3000 and adjust from there.`n`n"
FaqT .= "This is the pause between finishing a catch and the next cast. Too short and the cast is wasted while the game is still showing the catch.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "9.  IT MAKES A STRAY CAST RIGHT AFTER A MINIGAME`n`n"
FaqT .= "First raise Restart delay (ms) in General.`n`n"
FaqT .= "If it still happens, the macro is probably mistaking something on screen for the minigame after it ends, then clicking. Stop the macro, press Test detection in Minigame with no minigame on screen, and lower Fish line tolerance or remove extra colors until nothing is detected.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqTexts.Push(FaqT)
FaqT := ""
FaqT .= "Problems between the cast and the minigame.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "1.  IT CASTS BUT NEVER SHAKES`n`n"
FaqT .= "Check Shake mode in Shake. Navigation uses the keyboard to press the shake button, and Disabled does not shake at all.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "2.  NAVIGATION MODE DOES NOTHING`n`n"
FaqT .= "Set In-game navigation key in Shake to the key Roblox uses to turn on UI navigation. It is backslash by default.`n`n"
FaqT .= "If you changed that key in your Roblox settings, the macro needs the same key.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "3.  SHAKING IS TOO SLOW AND THE FISH GETS AWAY`n`n"
FaqT .= "Lower Navigation spam delay (ms) in Shake.`n`n"
FaqT .= "Going too low can make the game miss inputs, so lower it a little at a time.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "4.  IT SHAKES FOREVER AND NEVER REACHES THE MINIGAME`n`n"
FaqT .= "Check the minigame is actually being detected (see the Minigame tab). The macro keeps shaking until it sees the minigame.`n`n"
FaqT .= "Navigation failsafe (s) in Shake sets how long it shakes before giving up and casting again.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqTexts.Push(FaqT)
FaqT := ""
FaqT .= "Problems once the reeling bar appears. Use Test detection in Minigame to see what the macro can see.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "1.  THE MINIGAME IS NEVER DETECTED`n`n"
FaqT .= "Stop the macro, press Test detection in Minigame, then cast and play a minigame yourself. It shows whether the bar and the fish line are being seen.`n`n"
FaqT .= "If they are not, open the Color Manager (F9) and pick the colors again while the minigame is on screen. Each color keeps a list, so if the bar looks different at night or while it fills, add that shade too.`n`n"
FaqT .= "Raise Fish line tolerance a little at a time if picking again does not help. Colors differ between rod skins, so a new rod often needs a fresh pick.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "2.  TEST DETECTION NEVER SHOWS THE ARROW`n`n"
FaqT .= "That is normal on many rods. The arrow is only a backup used when the bar itself cannot be seen, so the bar and fish line are what matter.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "3.  IT THINKS A MINIGAME IS ON SCREEN WHEN THERE IS NONE`n`n"
FaqT .= "Your tolerances are too high or a picked color matches scenery. Lower Fish line tolerance and Bar color tolerance, and remove any colors in the Color Manager that do not belong to the bar.`n`n"
FaqT .= "Check with Test detection while no minigame is on screen. Nothing should be detected.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "4.  THE BAR IS FOUND BUT DOES NOT FOLLOW THE FISH`n`n"
FaqT .= "Check Special rod in Minigame. It must match the rod you are holding, or set it to None for a normal rod.`n`n"
FaqT .= "Try Precision as the Detection mode. It needs the least tuning. Lines reads the edges of the bar instead of your colors, which helps if your colors keep failing.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "5.  THE BAR WOBBLES OR ROCKS AROUND THE FISH`n`n"
FaqT .= "Precision or Lines: raise Kd a little, then raise Stopping Distance if it still overshoots. Change one value at a time.`n`n"
FaqT .= "Near the fish the macro clicks rapidly on its own to hold the bar centered, so a small amount of fast clicking there is expected.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "6.  THE BAR SAILS PAST THE FISH`n`n"
FaqT .= "Raise Stopping Distance in Minigame. It starts braking sooner.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "7.  THE BAR CRAWLS AND NEVER REACHES THE FISH`n`n"
FaqT .= "Lower Stopping Distance, or raise Kp a little.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "8.  THE BAR FALLS BEHIND A FISH THAT MOVES FAST`n`n"
FaqT .= "Raise Kp a little. Raising Velocity Smoothing makes it react to direction changes sooner, but too high makes it jittery.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "9.  THE BAR GETS STUCK AGAINST ONE EDGE`n`n"
FaqT .= "Usually the steering is too weak to pull it back. Raise Stopping Distance first.`n`n"
FaqT .= "On Manual mode, change Side bar ratio and Side wait multiplier in Minigame.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "10.  THE BLUE BAR ON THE OVERLAY KEEPS CHANGING SIZE`n`n"
FaqT .= "When the bar gets pushed into the edge of the minigame, part of it is cut off, so it is measured smaller. Fix the steering first (see above) and the size usually settles.`n`n"
FaqT .= "A short size change right as a minigame starts or ends is normal.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "11.  MANUAL MODE WILL NOT TRACK PROPERLY`n`n"
FaqT .= "Manual needs tuning by hand, so try Precision first. If you stay on Manual, follow Quick rules in Minigame: Right values higher than Left, Unstable higher than Stable, every Division between 1.0 and 1.5, and change one value by about 15% at a time.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "12.  THE MINIGAME GIVES UP AND RECASTS`n`n"
FaqT .= "Minigame failsafe (s) in Minigame is the longest one minigame may last before the macro re-equips and casts again. Raise it if your fish take longer than 60 seconds.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "13.  SOME DETECTION MODES ARE MISSING`n`n"
FaqT .= "Special rods only list the modes that work with them. Set Special rod to None to see all three.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "14.  I MESSED UP MY MINIGAME SETTINGS`n`n"
FaqT .= "Press Restore defaults in Minigame. It resets the Minigame setup and every color in the Color Manager, so pick your colors again afterwards.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqTexts.Push(FaqT)
FaqT := ""
FaqT .= "Rods with their own mechanics. Pick the rod in Minigame > Special rod. Settings in yellow are specific to that rod.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "1.  I PICKED A SPECIAL ROD AND IT STILL DOES NOT WORK`n`n"
FaqT .= "Stop the macro and start it again after changing Special rod. Some rods watch a different part of the screen, and that is only measured when the macro starts.`n`n"
FaqT .= "Check you are holding the rod you picked. The wrong setting on the wrong rod steers badly.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "2.  CASTBOUND`n`n"
FaqT .= "Castbound finds the bar on its own. If it never picks up the bar on your screen, add the colors your screen shows under Extra colors on its Setup page: open the Color Manager, Pick from screen, and click the purple track first (also where it runs over bright scenery), then the purple sword marker. Bar colors only help if the bar looks very dark. Leave them all empty if it already works - empty means the built-in detection, unchanged. Clear this list in the Color Manager empties one again.`n`n"
FaqT .= "Its bar shrinks and grows during the fight. That is the rod, not a detection problem. If the bar rocks or overshoots, raise Stopping Distance.`n`n"
FaqT .= "The game freezes the minigame for about a second now and then. The macro holds steady until it moves again.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "3.  REMEMBRANCE`n`n"
FaqT .= "Set Rod state to Living or Departed to match your rod. Switching it fills in the right bar colors for that state.`n`n"
FaqT .= "The goal is to keep the bar on the white fish line and away from the black one. On Living, covering both only pauses progress. On Departed, covering both loses progress, so the bar steers clear of the black line even if it briefly leaves the white one.`n`n"
FaqT .= "The pink marker on the overlay shows where the macro sees the black line. Restart the macro after picking this rod.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "4.  PINIONS ARIA`n`n"
FaqT .= "The bar stays on the fish and catches every note it can without leaving it. It only leaves the fish for a note when the catch progress can afford the trip. Leave the note settings at their defaults unless you see one of these.`n`n"
FaqT .= "During a fight a line under the bar reads Pinions: progress NN% | reason. The reason tells you what to change:`n`n"
FaqT .= "- no note, while notes are visibly falling: detection. Check Note color in the Color Manager, then raise Note tolerance to 18-22 (above 25 the fish icon counts as a note).`n"
FaqT .= "- skip: progress NN%: the macro chose the fish over that note on purpose. Nothing to change. If fish are being LOST while the bar is away on a note, lower Note priority to 80 or 60.`n"
FaqT .= "- skip: too far: the note landed where the bar could not reach in time. No setting changes that.`n"
FaqT .= "- progress ?: the progress bar could not be read. Report it with your resolution and UI scale.`n`n"
FaqT .= "Resonance state (the fish locked to the bar, notes falling two at a time) is detected on its own: the bar then goes straight for every note until one is missed, and the status line reads resonance. Resonance hand-off (px) is how many pixels before a note lands the bar leaves for the next one; 50 is right for most people.`n`n"
FaqT .= "Notes are searched for across the Shake search area, so it must cover the whole minigame.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "5.  REQUIEM`n`n"
FaqT .= "If the reel keeps snapping, raise Min hold (ms) and Min release (ms). If the bar feels sluggish or falls behind, lower them.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "6.  NOISEFORM AND VERDANT OATH`n`n"
FaqT .= "Picking these rods fills in their colors for you. If detection is off afterwards, pick the colors again in the Color Manager.`n`n"
FaqT .= "Verdant Oath: only the green part of the bar counts. The macro keeps the fish line inside the green and off the wood at both ends, because touching the wood costs progress. Lines is the default. Precision is a backup: it finds the green by its color and the fish by Fish line color, which picking the rod fills in.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "7.  DARKHEART, LULLABY, DREAMBREAKER AND BELLONAS WARAXE`n`n"
FaqT .= "These only allow the detection modes that work with them. Use Lines, or Precision where it is offered, and tune Kp, Kd and Stopping Distance as usual.`n`n"
FaqT .= "Dreambreaker: a few seconds into the minigame the controls flip - the bar starts drifting right and clicking moves it left. The macro switches over by itself about 1.5 s after the bar starts moving. No right clicks are needed.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "8.  MIGUROD`n`n"
FaqT .= "MiguRod finds its bar on its own, so the bar colors do not matter for it. If the bar on the overlay looks wrong, that is worth reporting. The pale fish line is still matched by color, so pick that again in the Color Manager if the macro loses track of it.`n`n"
FaqT .= "The red exclamation marks slice the bar when they strike, which makes it shorter. That cannot really be avoided, so the macro does not try to dodge them and just keeps following the fish.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "9.  TRYHARD ROD`n`n"
FaqT .= "Finds its bar and fish line on its own. The bar turns dark red, almost the color of the track, whenever the fish is outside it - the macro still sees it and keeps chasing.`n`n"
FaqT .= "If the bar is never picked up on your screen, add the colors your screen shows under Extra colors on its Setup page (Color Manager, Pick from screen): the bar while the fish is inside it and while it is outside, then the dark marker above the bar if the fish is not found. Leave them empty if it already works - empty means the built-in detection, unchanged.`n`n"
FaqT .= "The bar is very small and the fish slips out easily. That is the rod, not a detection problem. If the bar rocks or overshoots, raise Stopping Distance.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "10.  HALIBUT HARPOON`n`n"
FaqT .= "Play minigame (on by default) sends the bar to the exclamation mark when it appears. Turn it off to keep the bar on the fish line the whole time.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "11.  STELLARWAVE MELODY`n`n"
FaqT .= "Finds its bar and fish on its own. While the zodiac signs are on the bar it clicks them in the order shown above the bar (the signs appear in that order) and keeps reeling in between; when they are gone it reels as normal.`n`n"
FaqT .= "Keep the mouse cursor free during fights: no shift lock, no first person, camera mode off. If the cursor cannot reach a sign the macro stops clicking for that cast and just reels.`n`n"
FaqT .= "Click the signs (on by default) can be turned off on its Setup page if the clicks make your fights worse.`n`n"
FaqT .= "Fast sign clicks (off by default) clicks each sign as soon as it appears, with a shorter click, so the signs go faster. Turn it off again if signs get missed or the wrong sign gets clicked.`n`n"
FaqT .= "Retry failed clicks (off by default) clicks a sign again when its click did not go through, up to 3 times a moment apart, and spots a failed click sooner. When the next sign does not look like the one it expects, it looks for the right sign among the signs on the bar and clicks that one instead - it never clicks a sign that looks wrong. With it off there are fewer retries, and a sign that does not look right stops the sign clicks until the next signs appear.`n`n"
FaqT .= "Its bar and fish colors are under Stellarwave colors on its Setup page, filled in with the rod's own colors. Change them only if the bar or fish is not picked up on your screen: open the Color Manager, Pick from screen, and click that part in game. Empty a box to go back to the normal color.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqTexts.Push(FaqT)
FaqT := ""
FaqT .= "Problems with Auto Totem, Auto Aquarium, Auto Keeperbound and the Discord webhook. Turn each one on in Utilities first.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "1.  AUTO TOTEM DOES NOTHING`n`n"
FaqT .= "Totems only work in private servers. They cannot be used in public ones.`n`n"
FaqT .= "Pick a totem in Target Event 1, and fill in the hotbar key for that totem. Day and Night need your Sundial key.`n`n"
FaqT .= "You can pick up to three totems in Target Event 1, 2 and 3. They are tried in that order. Totems that clash are not offered in the other boxes: only one weather totem (Clearcast, Tempest, Windset or Smokescreen), only one surge (Shiny, Sparkling or Mutation), and no totems that need opposite times of day. Aurora and Starfall already make it Night and Eclipse makes it Day, so Night or Day cannot be picked next to them.`n`n"
FaqT .= "If the Totem page says no effect, the macro used that totem but the icons did not change, so it waits 3 minutes (1.5 minutes for a Sundial) before trying it again. Check that totem's hotbar key.`n`n"
FaqT .= "If it says unknown, an icon in the bottom right was not recognised. One that appears right after a totem is used counts as that totem.`n`n"
FaqT .= "Shiny and Sparkling show the same star icon, so only one of them can be picked.`n`n"
FaqT .= "Only one surge (Shiny, Sparkling or Mutation) can be up at a time, so a surge totem is not used while another surge is active.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "2.  AUTO TOTEM USES THE WRONG TOTEM OR MISREADS THE WEATHER`n`n"
FaqT .= "The macro reads the time and weather icons in the bottom right of your screen. Make sure nothing covers them.`n`n"
FaqT .= "Camera mode hides those icons, so it stays off while Auto Totem is on.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "3.  AUTO TOTEM USED A SUNDIAL I DID NOT PICK`n`n"
FaqT .= "That is on purpose. If a totem needs a different time of day, it uses a Sundial first and waits for the time to change.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "4.  MY ROD IS NOT BACK IN MY HAND AFTER A TOTEM`n`n"
FaqT .= "Set Rod hotbar slot key in General > Recovery. It is used to re-equip the rod after popping a totem.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "5.  AUTO TOTEM CHECKS TOO OFTEN OR NOT OFTEN ENOUGH`n`n"
FaqT .= "Change Check every (s). Pop delay (ms) is the wait after using a totem before it checks again.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "6.  AUTO AQUARIUM SAYS IT COULD NOT FIND THE FISH FOOD PANEL`n`n"
FaqT .= "The macro presses Aquariums at the top of the screen. Make sure that bar is visible and nothing is covering it. Camera mode hides it, so it stays off while this is on.`n`n"
FaqT .= "If the menu is slow to open on your PC, raise Menu delay (ms).`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "7.  AUTO AQUARIUM SKIPS SOME FISH FOOD`n`n"
FaqT .= "Raise Step delay (ms) so each press has time to register, and raise Scroll sweep (notches) if food far along the row is being missed. Cards per trip limits how many cards it handles.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "8.  AUTO AQUARIUM SPENDS TOO MUCH MONEY`n`n"
FaqT .= "Lower Buy limit per trip. Run every (minutes) controls how often it visits.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "9.  AUTO KEEPERBOUND DOES NOTHING`n`n"
FaqT .= "It needs the ENCHANT ANYWHERE gamepass. Without it the enchant button does nothing.`n`n"
FaqT .= "Put your Enchant Relic in a hotbar slot and type that number into Relic hotbar key.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "10.  AUTO KEEPERBOUND SAYS IT COULD NOT OPEN THE INVENTORY`n`n"
FaqT .= "Set Inventory key to the key that opens your inventory. It is G by default. Raise Menu delay (ms) if your inventory is slow to open.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "11.  AUTO KEEPERBOUND SAYS ENCHANT ROD DID NOTHING`n`n"
FaqT .= "Use Set under Button positions to show the macro exactly where the Enchant Rod and Confirm buttons are.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "12.  MY HOTBAR NUMBER KEYS STOPPED WORKING`n`n"
FaqT .= "The Enchant your Rod confirm box is probably still open. While it is open the game ignores number keys. Press Cancel on it. The macro closes it by itself before each recharge.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "13.  HOW MANY RECHARGES DO I NEED`n`n"
FaqT .= "A Keeperbound rod loses about 0.2% power per catch, and each recharge gives back about 5%. 50 catches drain about 10%, so set Recharges per trip to 2 if Every (catches) is 50.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "14.  THE WEBHOOK TEST SAYS IT COULD NOT SEND`n`n"
FaqT .= "Paste the full Discord webhook link into Webhook URL. It should start with https://discord.com/api/webhooks/. Check you are online.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "15.  I GET NO WEBHOOK MESSAGES`n`n"
FaqT .= "Turn the webhook On in Utilities and on its own page, and press Send test message to check the link works.`n`n"
FaqT .= "Catch messages need Send a message for every catch. Stopped and no-catch alerts need Send alerts. Status reports are sent every Status report every (min) minutes.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqT .= "16.  I DO NOT WANT MY NAME OR MONEY IN WEBHOOK SCREENSHOTS`n`n"
FaqT .= "Untick Attach a screenshot to status reports. The screenshot shows your whole screen, including your username, level and cash.`n`n"
FaqT .= "--------------------------------------------------------`n"
FaqTexts.Push(FaqT)

Gui, Font, s9 Bold c%ColorMuted%, Segoe UI
FaqTabH := []
FaqTabX := CARDX
for i, nm in FaqNames
	{
	Gui, Add, Text, x%FaqTabX% y152 w88 h28 Center +0x100 +0x200 vFaqTab%i% gFaqTabClick HwndhFT, %nm%
	RoundCtrl(hFT, 88, 28, 8)
	FaqTabH.Push(hFT)
	FaqCtrls.Push(hFT)
	FaqTabX += 93
	}

Gui, Font, s9 Norm cFFFFFF, Consolas
FaqStart := FaqTexts[1]
Gui, Add, Edit, x%CARDX% y186 w%CARDW% h314 ReadOnly VScroll +0x4 vFaqBox HwndhFaqBox, %FaqStart%
FaqCtrls.Push(hFaqBox)
ThemedCtrls.Push(hFaqBox)
SpecialBrushes[hFaqBox] := {brush: hBrushCard, text: 0xFFFFFF}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
FaqTab := 1
gosub, FaqPaintTabs

return

FaqTabClick:
FaqTab := SubStr(A_GuiControl, 7) + 0
GuiControl, 1:, FaqBox, % FaqTexts[FaqTab]
gosub, FaqPaintTabs
return

FaqPaintTabs:
for i, h in FaqTabH
	{
	if (i = FaqTab)
		SpecialBrushes[h] := {brush: hBrushAccent, text: 0x101010}
	else
		SpecialBrushes[h] := {brush: hBrushBorder, text: ColorTextBGR}
	WinSet, Redraw, , ahk_id %h%
	}
return

;====================================================================================================;

BuildAboutSection:

hC := AddPanel(CARDX, 120, CARDW, 74)
AboutCtrls.Push(hC)

Gui, Font, s14 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x%CX% y132 w%TXW% h28 HwndhAbtHdr, 🐟 DeepFish BETA
AboutCtrls.Push(hAbtHdr)
SpecialBrushes[hAbtHdr] := {brush: hBrushCard, text: ColorAccentBGR}
Gui, Font, s9 Norm cFFFFFF, Segoe UI
Gui, Add, Text, x%CX% y162 w%TXW% h18 HwndhAbtVer, Version %DFVersion%  •  Made by Yato
AboutCtrls.Push(hAbtVer)
SpecialBrushes[hAbtVer] := {brush: hBrushCard, text: 0xFFFFFF}

hC := AddPanel(CARDX, 204, CARDW, 106)
AboutCtrls.Push(hC)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y214 w%TXW% h16 HwndhAbtLinkHdr, LINKS
AboutCtrls.Push(hAbtLinkHdr)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
Gui, Add, Text, x%CX% y236 w%TXW% h20 +0x100 gOpenDiscord HwndhAbtDiscord, 💬  Discord  —  discord.gg/9dkmX6pAZd
AboutCtrls.Push(hAbtDiscord)
SpecialBrushes[hAbtDiscord] := {brush: hBrushCard, text: 0xFFFFFF}
Gui, Add, Text, x%CX% y258 w%TXW% h20 +0x100 gOpenYouTube HwndhAbtYouTube, ▶  YouTube  —  youtube.com/@yatoark
AboutCtrls.Push(hAbtYouTube)
SpecialBrushes[hAbtYouTube] := {brush: hBrushCard, text: 0xFFFFFF}
Gui, Add, Text, x%CX% y280 w%TXW% h20 +0x100 gOpenAsphalt HwndhAbtAsphalt, ▶  Original source  —  youtube.com/@AsphaltCake
AboutCtrls.Push(hAbtAsphalt)
SpecialBrushes[hAbtAsphalt] := {brush: hBrushCard, text: 0xFFFFFF}

hC := AddPanel(CARDX, 320, CARDW, 84)
AboutCtrls.Push(hC)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y330 w%TXW% h16 HwndhAbtCredHdr, CREDITS
AboutCtrls.Push(hAbtCredHdr)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
AboutCredits := "• Yato — Creator, design and development.`n"
AboutCredits .= "• AsphaltCake — Precision/Lines mode control method,`n"
AboutCredits .= "   adapted from IRUS IDIOTPROOF/IRUS COMET.`n"
Gui, Add, Text, x%CX% y352 w%TXW% h48 cFFFFFF HwndhAbtCred, %AboutCredits%
AboutCtrls.Push(hAbtCred)
SpecialBrushes[hAbtCred] := {brush: hBrushCard, text: 0xFFFFFF}

hC := AddPanel(CARDX, 414, CARDW, 96)
AboutCtrls.Push(hC)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y424 w%TXW% h16 HwndhAbtDonHdr, DONATIONS
AboutCtrls.Push(hAbtDonHdr)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
AboutDon := "Appreciated but never required. Message me directly`n"
AboutDon .= "on Discord for details please don't send a friend`n"
AboutDon .= "request, I get a lot.`n"
AboutDon .= "Accepting PayPal, Server Boosts and Discord Nitro."
Gui, Add, Text, x%CX% y446 w%TXW% h60 cFFFFFF HwndhAbtDon, %AboutDon%
AboutCtrls.Push(hAbtDon)
SpecialBrushes[hAbtDon] := {brush: hBrushCard, text: 0xFFFFFF}

hC := AddPanel(CARDX, 520, CARDW, 112)
AboutCtrls.Push(hC)
Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CX% y530 w%TXW% h16 HwndhAbtLicHdr, LICENCE
AboutCtrls.Push(hAbtLicHdr)
Gui, Font, s9 Norm cFFFFFF, Segoe UI
AboutLic := "© 2026 Yato. Personal use only. Do not redistribute,`n"
AboutLic .= "republish a modified build, or sell this macro. Reusing`n"
AboutLic .= "parts of it is fine as long as ""Yato"" is credited visibly`n"
AboutLic .= "in your project's interface. Provided as is, with no`n"
AboutLic .= "warranty — use at your own risk."
Gui, Add, Text, x%CX% y552 w%TXW% h76 cFFFFFF HwndhAbtLic, %AboutLic%
AboutCtrls.Push(hAbtLic)
SpecialBrushes[hAbtLic] := {brush: hBrushCard, text: 0xFFFFFF}

return

;====================================================================================================;

BuildReadThisSection:

ReadThisGroups := [ ["FISCH SETTINGS  (Menu)"
		, [ "Extra Brightness:   →   slider all the way to the RIGHT (max)"
		  , "Camera Shake   →   OFF"
		  , "Fishing Minigame Shake:   →   slider all the way to the LEFT (0)"
		  , "Show Enchant Info   →   OFF" ] ]
	, ["WINDOWS / ROBLOX"
		, [ "Run Roblox in FULLSCREEN. If detection then fails on your PC, use windowed fullscreen instead."
		  , "Windows display scale must be 100% (Settings > System > Display > Scale), then restart your PC."
		  , "Turn OFF HDR in Windows (Settings > System > Display > HDR). HDR changes the colors the macro looks for."
		  , "Do not resize, move or un-fullscreen the Roblox window while the macro is running - it measures the window once at Start."
		  , "Set Roblox graphics quality to low, or leave Auto-lower graphics ticked in General." ] ] ]
ReadThisImages := [ "Images\readthis1.png", "Images\readthis2.png", "Images\readthis3.png" ]

Gui, Font, s13 Bold c%ColorRed%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w%CARDW% h30 HwndhC, ⚠  Read this first
ReadThisCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorRedBGR}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CARDX% y152 w%CARDW% h18 HwndhC, These must be set exactly like this before you press Start.
ReadThisCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}
Gui, Font, s9 Bold c%ColorRed%, Segoe UI
rtMsg := ReadThisAccepted ? "✔  Unlocked - you can use every tab and Start." : "🔒  Locked - tick the box below to unlock the other tabs and Start."
Gui, Add, Text, x%CARDX% y172 w%CARDW% h18 HwndhReadThisLockMsg, %rtMsg%
ReadThisCtrls.Push(hReadThisLockMsg)
SpecialBrushes[hReadThisLockMsg] := {brush: hBrushBG, text: ReadThisAccepted ? ColorMutedBGR : ColorRedBGR}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

RtY := 198
hC := AddPanel(CARDX, RtY, CARDW, 80)
ReadThisCtrls.Push(hC)
Gui, Font, s8 Bold c%ColorRed%, Segoe UI
RtLY := RtY + 10
Gui, Add, Text, x%CX% y%RtLY% w%TXW% h16 HwndhC, UNLOCK
ReadThisCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorRedBGR}
Gui, Font, s9 Norm c%ColorText%, Segoe UI
RtLY += 22
rtChk := ReadThisAccepted ? "Checked" : ""
Gui, Add, CheckBox, x%CX% y%RtLY% w%TXW% h20 c%ColorText% vReadThisChk %rtChk% gReadThisAccept HwndhC, I have read all of this and set everything above
ReadThisCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
Gui, Font, s8 Norm c%ColorMuted%, Segoe UI
RtLY += 24
Gui, Add, Text, x%CX% y%RtLY% w%TXW% h16 HwndhC, Ticking this unlocks the other tabs and Start. It is remembered in Settings.ini.
ReadThisCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}
RtY += 90
for gi, grp in ReadThisGroups
	{
	RtCardH := 36
	RtHeights := []
	for i, ln in grp[2]
		{
		RtN := Ceil(StrLen(ln) / 88)
		if (RtN < 1)
			RtN := 1
		RtHeights.Push(RtN * 16 + 8)
		RtCardH += RtN * 16 + 8
		}
	hC := AddPanel(CARDX, RtY, CARDW, RtCardH)
	ReadThisCtrls.Push(hC)
	Gui, Font, s8 Bold c%ColorRed%, Segoe UI
	RtLY := RtY + 10
	Gui, Add, Text, x%CX% y%RtLY% w%TXW% h16 HwndhC, % grp[1]
	ReadThisCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: ColorRedBGR}
	Gui, Font, s9 Norm cFFFFFF, Segoe UI
	RtLY += 24
	for i, ln in grp[2]
		{
		RtH := RtHeights[i] - 8
		Gui, Add, Text, x%CX% y%RtLY% w%TXW% h%RtH% HwndhC, % "•  " . ln
		ReadThisCtrls.Push(hC)
		SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}
		RtLY += RtHeights[i]
		}
	RtY += RtCardH + 10

	if (gi = 1)
		{
		for pi, img in ReadThisImages
			{
			RtPath := A_ScriptDir . "\" . img
			if (!FileExist(RtPath))
				continue
			Gui, Add, Picture, x%CARDX% y%RtY% w%CARDW% h-1 HwndhC, %RtPath%
			ReadThisCtrls.Push(hC)
			CtrlSnapPos(hC, RtPX, RtPY, RtPW, RtPH)
			RtY += RtPH + 10
			}
		}
	}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

return

;====================================================================================================;

BuildVersionsSection:

VersionNotes := []
VersionNotes.Push(["Version 2.0", ["Info panel you can place anywhere on any monitor (replaces the old tooltips), with a Signs row for Stellarwave"
	, "Fish scanner + Fischipedia value calculator, counts Extra! fish too"
	, "Adaptive casting (cast X ms after the minigame closes, negative = sooner)"
	, "Stellarwave ends the fight the moment its bar and stars are gone (no more 450 ms wait)"
	, "Stellarwave: Wait for N signs (1-12) before clicking"
	, "Stellarwave: Retry failed clicks reworked - never clicks a wrong-looking sign, retries sooner"
	, "Stellarwave Max sign speed: a stray mouse move or star misread no longer stops sign clicking"
	, "Keeperbound: auto power bar reading, read while the bobber flies, never recharges during a minigame"
	, "Keeperbound: no longer puts the rod away after a failed recharge"
	, "Smart cast can cast N times in a row (each cast waits Cast hold + 50 ms before the next)"
	, "Fish value list downloads the first time you turn on the scanner, stays saved, and updates every Monday 6 PM US Eastern"
	, "Installs check in with the owner when they start (Install ID, keyed or not, version)"
	, "Miscellaneous tab with Pogo Jump Tech: one hotkey (any key or mouse side button) does pogo stick, wait, jump coil, jump (every key and pause adjustable)"
	, "Stellarwave preset Ominous Ouija: reads the letter tokens and clicks them in GRIMPLANCHET order"
	, "Ominous Ouija now finds its own bar and fish (the grey-rimmed bar on the wooden track, the planchette) and starts the minigame"
	, "Minor changes / bug fixes"]])
VersionNotes.Push(["ULTIMATE builds 19-24", ["Smart cast, auto power bar read for Keeperbound, passive mode for every rod"
	, "Old Max sign speed engine is back, Signs before bar is back"
	, "New look: Fishing dashboard, themes (Mono default), live stats"]])
VersionNotes.Push(["Version 1.1.7 (mod build 18)", ["Merged the official 1.1.7 (Dreambreaker fix, faster Stellarwave engine) into this build"
	, "Stellarwave: Wait for all signs, then click them in one fast burst"]])
VersionNotes.Push(["Version 1.1.7", ["Fixed Dreambreaker"
	, "Made Stellarwave Melody WAY faster"]])
VersionNotes.Push(["Version 1.1.6", ["Made Stellarwave Melody a lot lot lot lot lot faster"]])
VersionNotes.Push(["Version 1.1.5", ["Fixed Stellarwave Melody"
	, "Made Stellarwave Melody click signs faster"]])
VersionNotes.Push(["Version 1.1.4", ["Added Stellarwave Melody"
	, "Added extra configurability to Castbound & Tryhard Rod"
	, "Added Play Minigame option in Halibut Harpoon"
	, "Added extra option for a 3rd totem"
	, "Fixed Bellonas Waraxe"
	, "Fixed Tranquility"
	, "Fixed Auto Totem"
	, "Fixed Bugs"]])
VersionNotes.Push(["Version 1.0.4", ["Added Verdant Oath"
	, "Added Tryhard Rod"
	, "Fixed Noiseform"
	, "Fixed Auto Totems"]])
VersionNotes.Push(["Version 1.0.3", ["Improved Pinions Aria Tracking"]])
VersionNotes.Push(["Version 1.0.2", ["Added Splitbranch Twig"
	, "Fixed the bar giving up mid-minigame"
	, "Improved perfect casting"
	, "Improved minigame start and end detection"
	, "Improved tracking when the fish leaves the bar"
	, "Smoother overlay"
	, "Updates now install automatically"
	, "Removed Click shake mode"]])
VersionNotes.Push(["Version 1.0.1", ["Fixed Castbound"
	, "Improved Pinions Aria note tracking"]])
VersionNotes.Push(["Version 1.0.0", ["Added Remembrance Rod"
	, "Added Castbound Rod"
	, "Added MiguRod"
	, "Added Halibut Harpoon Rod"
	, "Added Color Manager"
	, "Added Auto Update"
	, "Updated FAQ"
	, "Fixed Bugs"]])

Gui, Font, s13 Bold c%ColorText%, Segoe UI
Gui, Add, Text, x%CARDX% y120 w%CARDW% h30 HwndhC, Versions
VersionsCtrls.Push(hC)
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x%CARDX% y152 w%CARDW% h18 HwndhC, What changed in each update.
VersionsCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushBG, text: ColorMutedBGR}

VerY := 180
for vi, vn in VersionNotes
	{
	VerCardH := 44 + (vn[2].Length() * 20) + 10
	hC := AddPanel(CARDX, VerY, CARDW, VerCardH)
	VersionsCtrls.Push(hC)
	Gui, Font, s11 Bold cFFFFFF, Segoe UI
	VerTY := VerY + 12
	Gui, Add, Text, x%CX% y%VerTY% w%TXW% h24 HwndhC, % vn[1]
	VersionsCtrls.Push(hC)
	SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}
	Gui, Font, s9 Norm cFFFFFF, Segoe UI
	VerLY := VerY + 44
	for li, ln in vn[2]
		{
		Gui, Add, Text, x%CX% y%VerLY% w%TXW% h20 0x80 HwndhC, % "•  " . ln
		VersionsCtrls.Push(hC)
		SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}
		VerLY += 20
		}
	VerY += VerCardH + 10
	}
Gui, Font, s9 Norm c%ColorMuted%, Segoe UI

return

;====================================================================================================;

VersionsClick:
TargetSection := "Versions"
gosub, ShowSection
return

;====================================================================================================;

OpenDiscord:
Run, https://discord.gg/9dkmX6pAZd
return

OpenYouTube:
Run, https://www.youtube.com/@yatoark
return

OpenAsphalt:
Run, https://www.youtube.com/@AsphaltCake
return

;====================================================================================================;

SidebarClick:
TargetSection := SubStr(A_GuiControl, 4)
gosub, ShowSection
return

;====================================================================================================;

ReadThisAccept:
GuiControlGet, ReadThisChk, 1:, ReadThisChk
ReadThisAccepted := ReadThisChk ? 1 : 0
IniWrite, %ReadThisAccepted%, %SettingsFile%, GUI, ReadThisAccepted
gosub, ApplyReadThisLock
if (hReadThisLockMsg)
	{
	if (ReadThisAccepted)
		rtMsg := "✔  Unlocked - you can use every tab and Start."
	else
		rtMsg := "🔒  Locked - tick the box below to unlock the other tabs and Start."
	SpecialBrushes[hReadThisLockMsg] := {brush: hBrushBG, text: ReadThisAccepted ? ColorMutedBGR : ColorRedBGR}
	GuiControl, 1:, %hReadThisLockMsg%, %rtMsg%
	}
if (ReadThisAccepted)
	{
	TargetSection := "General"
	gosub, ShowSection
	}
return

ReadThisLockedNotice:
if (!WinExist("DeepFish BETA"))
	Gui, 1:Show
TargetSection := "ReadThis"
gosub, ShowSection
msgbox, 4144, DeepFish, Read the READ THIS page first`, then tick the box under its title to unlock Start and the other tabs.
return

ApplyReadThisLock:
for rtI, rtD in NavDefs
	{
	rtK := rtD[1]
	if (rtK = "ReadThis" or !NavHwnd.HasKey(rtK))
		continue
	GuiControl, % (ReadThisAccepted ? "1:Show" : "1:Hide"), % NavHwnd[rtK]
	GuiControl, % (ReadThisAccepted ? "1:Show" : "1:Hide"), % NavHwnd["bar" . rtK]
	}
if (hVersionsBtn)
	GuiControl, % (ReadThisAccepted ? "1:Show" : "1:Hide"), %hVersionsBtn%
return

;====================================================================================================;

MiniTabClick:
MiniTab := (A_GuiControl = "MiniTabColors") ? "Colors" : "Setup"
TargetSection := "Minigame"
gosub, ShowSection
return

;====================================================================================================;

ShowSection:

if (!ReadThisAccepted and TargetSection != "ReadThis")
	TargetSection := "ReadThis"
if (GuiHwnd)
	DllCall("SendMessage", "Ptr", GuiHwnd, "UInt", 0x000B, "Ptr", 0, "Ptr", 0)
NeedSection := TargetSection
gosub, EnsureSection

OnUtil := (TargetSection = "Utilities")
OnTotem := (TargetSection = "Totem")
OnAqua := (TargetSection = "Aquarium")
OnKeep := (TargetSection = "Keeper")
OnAdv := (TargetSection = "Advanced")
OnGuess := (TargetSection = "Guess")
OnWeb := (TargetSection = "Webhook")
OnMini := (TargetSection = "Minigame")
OnCast := (TargetSection = "Cast")
OnSetup := (OnMini and MiniTab != "Colors")
OnColors := (OnMini and MiniTab = "Colors")
SecTopEdge := (OnMini ? 158 : 120) - YS

ShowList(GeneralCtrls, TargetSection = "General")
ShowList(HomeCtrls, TargetSection = "Home")
if (TargetSection = "Home")
	{
	gosub, HomeSync
	gosub, HomeTick
	SetTimer, HomeTick, 250
	}
else
	SetTimer, HomeTick, Off
ShowList(CastCtrls, OnCast)
ShowList(NormalCastCtrls, OnCast and CastMode = "Normal")
ShowList(PerfectCastCtrls, OnCast and CastMode != "Normal")
ShowList(ShakeCtrls, TargetSection = "Shake")
ShowList(UtilCtrls, OnUtil)
ShowList(MiscCtrls, TargetSection = "Misc")
ShowList(FaqCtrls, TargetSection = "Faq")
ShowList(AboutCtrls, TargetSection = "About")
ShowList(VersionsCtrls, TargetSection = "Versions")
ShowList(ReadThisCtrls, TargetSection = "ReadThis")

; ---- Minigame: two faces, Setup and the Color Manager ----
GuiControl, % (OnMini ? "1:Show" : "1:Hide"), MiniTabSetup
GuiControl, % (OnMini ? "1:Show" : "1:Hide"), MiniTabColors
if (OnSetup)
	LayoutMinigame()
for nm, b in MgBlocks
	{
	MgOn := (OnSetup and MgVisible.HasKey(nm))
	GuiControl, % (MgOn ? "1:Show" : "1:Hide"), % b.card
	ShowList(b.ctrls, MgOn)
	}
ShowList(CMCtrls, OnColors)
if (OnColors)
	gosub, CMRefresh
if (MiniTabSetupH)
	{
	if (OnColors)
		{
		SpecialBrushes[MiniTabSetupH] := {brush: hBrushBorder, text: ColorTextBGR}
		SpecialBrushes[MiniTabColorsH] := {brush: hBrushAccent, text: 0x101010}
		}
	else
		{
		SpecialBrushes[MiniTabSetupH] := {brush: hBrushAccent, text: 0x101010}
		SpecialBrushes[MiniTabColorsH] := {brush: hBrushBorder, text: ColorTextBGR}
		}
	}

; ---- Totem ----
ShowList(TotemCtrls, OnTotem)
if (OnTotem and !TotemAuto)
	ShowList(TotemBodyCtrls, false)
gosub, RefreshTotemKeys
if (OnTotem)
	SetTimer, TotemStatusTick, 1000
else
	SetTimer, TotemStatusTick, Off

; ---- Keeperbound ----
ShowList(KeeperCtrls, OnKeep)
if (OnKeep and !KeeperAuto)
	ShowList(KeeperBodyCtrls, false)
if (OnKeep)
	{
	gosub, KeeperRefreshSpots
	gosub, KeeperStatusTick
	SetTimer, KeeperStatusTick, 1000
	}
else
	SetTimer, KeeperStatusTick, Off

; ---- Advanced timings ----
ShowList(AdvCtrls, OnAdv)
if (OnAdv)
	gosub, AdvRefresh

; ---- Stellarwave auto retry ----
ShowList(GuessCtrls, OnGuess)
if (OnGuess and !SwGuessOn)
	ShowList(GuessBodyCtrls, false)
if (OnGuess)
	gosub, SwGuessRefresh

; ---- Aquarium ----
ShowList(AquariumCtrls, OnAqua)
if (OnAqua and !AquariumAuto)
	ShowList(AquariumBodyCtrls, false)
if (OnAqua)
	{
	gosub, AquariumStatusTick
	SetTimer, AquariumStatusTick, 1000
	}
else
	SetTimer, AquariumStatusTick, Off

; ---- Webhook ----
ShowList(WebhookCtrls, OnWeb)
if (OnWeb and !WebhookOn)
	ShowList(WebhookBodyCtrls, false)

if (TargetSection = "Faq" and hFaqBox)
	{
	SendMessage, 0xB1, 0, 0, , ahk_id %hFaqBox%
	SendMessage, 0xB7, 0, 0, , ahk_id %hFaqBox%
	}

GuiControl, 1:, UtilTotemOn, % (TotemAuto ? 1 : 0)
GuiControl, 1:, UtilAquariumOn, % (AquariumAuto ? 1 : 0)
GuiControl, 1:, UtilKeeperOn, % (KeeperAuto ? 1 : 0)
GuiControl, 1:, UtilGuessOn, % (SwGuessOn ? 1 : 0)
GuiControl, 1:, UtilWebhookOn, % (WebhookOn ? 1 : 0)

; ---- sidebar highlight (the two add-on pages keep Utilities lit) ----
NavActive := TargetSection
if (NavActive = "Advanced")
	NavActive := "General"
if (NavActive = "Totem" or NavActive = "Webhook" or NavActive = "Aquarium" or NavActive = "Keeper" or NavActive = "Guess")
	NavActive := "Utilities"
for i, d in NavDefs
	{
	nk := d[1]
	hv := NavHwnd[nk]
	hb := NavHwnd["bar" . nk]
	if (nk = NavActive)
		{
		SpecialBrushes[hv] := {brush: hBrushBorder, text: (nk = "ReadThis") ? ColorRedBGR : ColorTextBGR}
		SpecialBrushes[hb] := {brush: hBrushAccent, text: ColorAccentBGR}
		}
	else
		{
		SpecialBrushes[hv] := {brush: hBrushPanel, text: (nk = "ReadThis") ? ColorRedBGR : ColorNavBGR}
		SpecialBrushes[hb] := {brush: hBrushPanel, text: ColorTextBGR}
		}
	}
gosub, ApplyReadThisLock

CollectVisible()
ApplyScroll()
if (GuiHwnd)
	DllCall("SendMessage", "Ptr", GuiHwnd, "UInt", 0x000B, "Ptr", 1, "Ptr", 0)
gosub, RepaintGui

return

;====================================================================================================;

DetTestToggle:
if (DetTesting)
	{
	DetTesting := false
	SetTimer, DetTestTick, Off
	GuiControl, 1:, DetTestBtn, ▶  Test detection
	GuiControl, 1:, DetTestOut, Test stopped.
	Loop, 20
		tooltip, , , , %A_Index%
	return
	}
if (MacroRunning)
	{
	GuiControl, 1:, DetTestOut, Stop the macro first - the test needs the capture to itself.
	return
	}
DetTesting := true
Loop, 20
	tooltip, , , , %A_Index%
GuiControl, 1:, DetTestBtn, ⏹  Stop test
SetTimer, DetTestTick, 250
return

DetTestTick:
if (!DetTesting or TargetSection != "Minigame" or MacroRunning)
	{
	DetTesting := false
	SetTimer, DetTestTick, Off
	GuiControl, 1:, DetTestBtn, ▶  Test detection
	Loop, 20
		tooltip, , , , %A_Index%
	return
	}
gosub, ResolveRoblox
if (!RobloxHwnd)
	{
	GuiControl, 1:, DetTestOut, Roblox is not open.
	return
	}
gosub, Calculations
gosub, CaptureFishBar
if (SpecialRod = "Stellarwave Melody")
	{
	if (!SwReady)
		SwSetup()
	SwApplyColours()
	}
DetC := MgDetect()
DetTxt := "Bar " . (MgSawBar ? "✔" : "✘")
DetTxt .= "    Fish line " . (MgSawFish ? "✔" : "✘")
DetTxt .= "    Arrow " . ((MgSawArrow or FindArrowX() >= 0) ? "✔" : "✘")
DetTxt .= "    →  " . DetC . "%"
if (DetC >= 90)
	DetTxt .= "  solid"
else if (DetC >= 55)
	DetTxt .= "  usable"
else if (DetC > 0)
	DetTxt .= "  weak - re-pick colors"
else
	DetTxt .= "  nothing seen"
GuiControl, 1:, DetTestOut, %DetTxt%
return

;====================================================================================================;

RefreshControlModes:
if (SpecialRod = "Noiseform")
	CmList := "Precision"
else
if (SpecialRod = "Darkheart" or SpecialRod = "Pinions Aria" or SpecialRod = "Lullaby"
	or SpecialRod = "Castbound")
	CmList := "Lines"
else if (SpecialRod = "Remembrance")
	CmList := "Lines|Precision"
else if (SpecialRod = "MiguRod" or SpecialRod = "Halibut Harpoon" or SpecialRod = "Tryhard Rod" or SpecialRod = "Stellarwave Melody")
	CmList := "Precision"
else if (SpecialRod = "Requiem" or SpecialRod = "Bellona's Waraxe" or SpecialRod = "Dreambreaker"
	or SpecialRod = "Verdant Oath")
	CmList := "Lines|Precision"
else
	CmList := "Manual|Precision|Lines"
if (!InStr("|" . CmList . "|", "|" . ControlMode . "|"))
	{
	sp := InStr(CmList, "|")
	ControlMode := sp ? SubStr(CmList, 1, sp - 1) : CmList
	}
if (ControlModeDdl)
	{
	GuiControl, 1:, ControlMode, % "|" . CmList
	GuiControl, 1:ChooseString, ControlMode, %ControlMode%
	}
gosub, CMApplyTargets
return

;====================================================================================================;

AstraMigrateColours:
if (SpecialRod = "Astraenus Serenade")
	{
	SpecialRod := "None"
	ControlMode := "Precision"
	if ((FishColor = "0x434B5B" and BarLeftColor = "0xF1F1F1" and BarRightColor = "0xF1F1F1")
		or (FishColor = "0x8C7A7E" and BarLeftColor = "0xCCC19A" and BarRightColor = "0x845AC0"))
		{
		FishColor := "0x98816E"
		FishBarColorTolerance := 20
		BarLeftColor := "0xD8C55B"
		BarRightColor := "0x9E59FF"
		BarColorTolerance := 10
		}
	}
if (SpecialRod = "Chasm Stalker")
	SpecialRod := "None"
return

ApplyVerdantOathPreset:
FishColor := "0x434B5B"
BarLeftColor := "0x67512C"
BarRightColor := "0x65502D"
ArrowColor := "0x848587"
BarColorTolerance := 3
FishBarColorTolerance := 12
ArrowColorTolerance := 0
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, ArrowColor, %ArrowColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
GuiControl, 1:, ArrowColorTolerance, %ArrowColorTolerance%
gosub, RefreshSwatches
return

ApplyNoRodPreset:
NoRodSets := [ ["0x0C4125","0x33A95F"]                                                  ; Noiseform
	, ["0x0D0B0B","0x5D52A8"]                                                           ; Halibut Harpoon
	, ["0x434B5B","0x67512C"]                                                           ; Verdant Oath
	, ["0xFFFFFF","0x474747"], ["0xFFFFFF","0xB5B5B5"]                                  ; Remembrance
	, ["0xF9D9D4,0xFAD6CE,0xF9D4C7,0xF9D2C4,0xF8D0B7","0xE9B681,0xE0A66F,0xD1935B"] ]   ; MiguRod
NoRodHit := false
for i, s in NoRodSets
	{
	if (FishColor = s[1] and BarLeftColor = s[2] and (s.Length() < 3 or BarColorTolerance = s[3]))
		NoRodHit := true
	}
if (!NoRodHit)
	return
for i, f in ProfileFields
	{
	if (f[2] != "FishColor" and f[2] != "BarLeftColor" and f[2] != "BarRightColor" and f[2] != "ArrowColor"
		and f[2] != "BarColorTolerance" and f[2] != "FishBarColorTolerance" and f[2] != "ArrowColorTolerance")
		continue
	NoRodKey := f[2]
	%NoRodKey% := f[3]
	if (!NoRodQuiet)
		GuiControl, 1:, %NoRodKey%, % f[3]
	}
if (!NoRodQuiet)
	gosub, RefreshSwatches
return

ApplyHalibutPreset:
FishColor := "0x0D0B0B"
BarLeftColor := "0x5D52A8"
BarRightColor := "0x5D52A8"
ArrowColor := "0x413A76"
BarColorTolerance := 3
FishBarColorTolerance := 3
ArrowColorTolerance := 3
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, ArrowColor, %ArrowColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
GuiControl, 1:, ArrowColorTolerance, %ArrowColorTolerance%
gosub, RefreshSwatches
return

ApplyRemembrancePreset:
if (RemembranceMode = "Departed")
	{
	BarLeftColor := "0x474747"
	BarRightColor := "0x474747"
	BarColorTolerance := 8
	}
else
	{
	BarLeftColor := "0xB5B5B5"
	BarRightColor := "0xB5B5B5"
	BarColorTolerance := 10
	}
FishColor := "0xFFFFFF"
FishBarColorTolerance := 10
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
gosub, RefreshSwatches
return

ApplyMiguRodPreset:
BarLeftColor := "0xE9B681,0xE0A66F,0xD1935B"
BarRightColor := "0xE9B681,0xE0A66F,0xD1935B"
BarColorTolerance := 14
FishColor := "0xF9D9D4,0xFAD6CE,0xF9D4C7,0xF9D2C4,0xF8D0B7"
FishBarColorTolerance := 10
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
gosub, RefreshSwatches
return

RemembranceModeChanged:
GuiControlGet, RemembranceMode, 1:, RemembranceMode
gosub, ApplyRemembrancePreset
gosub, QueueAutoSave
return

ApplyNoiseformPreset:
FishColor := "0x0C4125"
BarLeftColor := "0x33A95F"
BarRightColor := "0x2C894D"
ArrowColor := "0x000000"
BarColorTolerance := 3
FishBarColorTolerance := 5
ArrowColorTolerance := 0
Kp := 0.3
Kd := 0.3
VelocitySmoothing := 0.5
StoppingDistanceMultiplier := 5.0
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, ArrowColor, %ArrowColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
GuiControl, 1:, ArrowColorTolerance, %ArrowColorTolerance%
GuiControl, 1:, Kp, %Kp%
GuiControl, 1:, Kd, %Kd%
GuiControl, 1:, VelocitySmoothing, %VelocitySmoothing%
GuiControl, 1:, StoppingDistanceMultiplier, %StoppingDistanceMultiplier%
gosub, RefreshSwatches
return

HalibutPlayChanged:
GuiControlGet, HaliChkV, 1:, HalibutPlayMinigame
if (!ErrorLevel)
	HalibutPlayMinigame := HaliChkV ? true : false
gosub, QueueAutoSave
return

SwClickChanged:
GuiControlGet, SwChkV, 1:, SwClickSigns
if (!ErrorLevel)
	SwClickSigns := SwChkV ? true : false
gosub, QueueAutoSave
return

SwRetryFailsChanged:
GuiControlGet, SwRetryV, 1:, SwRetryFails
if (!ErrorLevel)
	SwRetryFails := SwRetryV ? true : false
gosub, QueueAutoSave
return

OverlayOptChanged:
GuiControlGet, OvV, 1:, %A_GuiControl%
if (!ErrorLevel)
	%A_GuiControl% := OvV ? true : false
gosub, QueueAutoSave
return

SwPassiveChanged:
GuiControlGet, SwPasV, 1:, SwPassive
if (!ErrorLevel)
	SwPassive := SwPasV ? true : false
GuiControlGet, SwPasMsV, 1:, SwPassiveMs
if (!ErrorLevel and SwPasMsV != "")
	SwPassiveMs := SwPasMsV + 0
gosub, QueueAutoSave
return

SwMaxSignsChanged:
GuiControlGet, SwMaxV, 1:, SwMaxSigns
if (!ErrorLevel)
	SwMaxSigns := SwMaxV ? true : false
gosub, QueueAutoSave
return

SwSignsFirstChanged:
GuiControlGet, SwFirstV, 1:, SwSignsFirst
if (!ErrorLevel)
	SwSignsFirst := SwFirstV ? true : false
gosub, QueueAutoSave
return

SwAllSignsChanged:
GuiControlGet, SwAllV, 1:, SwAllSigns
if (!ErrorLevel)
	SwAllSigns := SwAllV ? true : false
gosub, QueueAutoSave
return

SwFastChanged:
GuiControlGet, SwFastV, 1:, SwFastClicks
if (!ErrorLevel)
	SwFastClicks := SwFastV ? true : false
gosub, QueueAutoSave
return

SwPresetChanged:
GuiControlGet, SwPreset, 1:, SwPreset
if (SwPreset != SwPresetCur)
	{
	; keep the colours of the preset left, show the ones of the preset picked (its own defaults the first time)
	if (SwPresetCur = "Ominous Ouija")
		SwColsOuija := SwColsGet()
	else
		SwColsNormal := SwColsGet()
	SwColsSet((SwPreset = "Ominous Ouija") ? ((SwColsOuija != "") ? SwColsOuija : SwColsOuijaDef) : ((SwColsNormal != "") ? SwColsNormal : SwColsNormalDef))
	for SwCi, SwCk in ["StellarBarColors","StellarBarTol","StellarFishColors","StellarFishTol","StellarHeadColors","StellarHeadTol"]
		GuiControl, 1:, %SwCk%, % %SwCk%
	gosub, RefreshSwatches
	SwPresetCur := SwPreset
	}
OjReset()
gosub, QueueAutoSave
return

SwRetryChanged:
GuiControlGet, SwRetryV, 1:, SwRetryClicks
if (!ErrorLevel)
	SwRetryClicks := SwRetryV ? true : false
gosub, QueueAutoSave
return

SpecialRodChanged:
GuiControlGet, SpecialRod, 1:, SpecialRod
if (SpecialRod = "Requiem" or SpecialRod = "Darkheart" or SpecialRod = "Lullaby"
	or SpecialRod = "Verdant Oath")
	ControlMode := "Lines"
if (SpecialRod = "Remembrance")
	ControlMode := "Lines"
if (SpecialRod = "MiguRod" or SpecialRod = "Halibut Harpoon" or SpecialRod = "Tryhard Rod" or SpecialRod = "Stellarwave Melody")
	ControlMode := "Precision"
gosub, ApplyNoRodPreset
if (SpecialRod = "Halibut Harpoon")
	gosub, ApplyHalibutPreset
if (SpecialRod = "Noiseform")
	gosub, ApplyNoiseformPreset
if (SpecialRod = "Remembrance")
	gosub, ApplyRemembrancePreset
if (SpecialRod = "MiguRod")
	gosub, ApplyMiguRodPreset
if (SpecialRod = "Verdant Oath")
	gosub, ApplyVerdantOathPreset
gosub, RefreshControlModes
TargetSection := "Minigame"
gosub, ShowSection
gosub, QueueAutoSave
return

;====================================================================================================;

ControlModeChanged:
GuiControlGet, ControlMode, , ControlMode
TargetSection := "Minigame"
gosub, ShowSection
gosub, QueueAutoSave
return

;====================================================================================================;

RefreshProfileList:

ProfileNames := "|"
Loop, Files, %ProfilesDir%\*.ini
	{
	SplitPath, A_LoopFileName, , , , NameNoExt
	ProfileNames .= NameNoExt . "|"
	}
GuiControl, 1:, ProfileSelect, %ProfileNames%
GuiControl, 1:ChooseString, ProfileSelect, %ActiveProfile%

return

;====================================================================================================;


;====================================================================================================;
;====================================================================================================;

MgCopyCode:

Gui, 1:Submit, NoHide
MgShareBad := ""
MgShareOut := "DF1;" . MgShareSig()
for MgShareI, MgShareF in MgShareFields()
	{
	MgShareK := MgShareF[2]
	MgShareV := %MgShareK%
	if (InStr(MgShareV, ";"))
		MgShareBad .= MgShareK . "`n"
	MgShareOut .= ";" . MgShareV
	}
if (MgShareBad != "")
	{
	msgbox, 4144, DeepFish, A settings code cannot hold a semicolon, and these fields contain one:`n`n%MgShareBad%`nTake the semicolons out, then copy again.
	return
	}
MgShareOut .= ";" . MgShareHash(MgShareOut)
clipboard := MgShareOut
MgCodeCue("✅ Code copied to clipboard")
settimer, MgShareStatusClear, -4000
return

;====================================================================================================;

MgCodeBoxChanged:
GuiControlGet, MgShareIn, 1:, MgCodeBox
MgCodeBoxLen := StrLen(MgShareIn)
MgCodeBoxJump := MgCodeBoxLen - MgCodeBoxPrevLen
MgCodeBoxPrevLen := MgCodeBoxLen
if (MgCodeBoxLen = 0 or MgCodeBoxJump < 10)
	return
gosub, MgApplyCode
MgCodeBoxPrevLen := 0
GuiControl, 1:, MgCodeBox,
return

;====================================================================================================;

MgApplyCode:

MgShareIn := StrReplace(MgShareIn, "`r", "")
MgShareIn := StrReplace(MgShareIn, "`n", "")
MgShareIn := StrReplace(MgShareIn, "`t", "")
MgShareIn := Trim(MgShareIn)
MgShareFlds := MgShareFields()
MgShareParts := StrSplit(MgShareIn, ";")
MgShareErr := ""
if (MgShareIn = "")
	MgShareErr := "That box is empty. Copy a settings code first, then paste it into the box."
else if (MgShareParts.MaxIndex() < 3 or MgShareParts[1] != "DF1")
	MgShareErr := "That is not a DeepFish settings code. A code starts with DF1 and is one long line of text."
else if (MgShareParts.MaxIndex() != MgShareFlds.MaxIndex() + 3 or MgShareParts[2] != MgShareSig())
	MgShareErr := "That code was made by a different version of DeepFish, so it cannot be read safely. Ask for a code from someone on this version."
else
	{
	MgShareChk := MgShareParts[MgShareParts.MaxIndex()]
	MgShareBody := SubStr(MgShareIn, 1, StrLen(MgShareIn) - StrLen(MgShareChk) - 1)
	if (MgShareChk != MgShareHash(MgShareBody))
		MgShareErr := "That code is damaged or was cut short. Copy the whole thing again and make sure nothing is missing."
	}

if (MgShareErr = "")
	{
	MgShareBad := ""
	for MgShareI, MgShareF in MgShareFlds
		{
		MgShareV := MgShareParts[MgShareI + 2]
		if (!ProfFieldOk(MgShareF[4], MgShareV))
			MgShareBad .= MgShareF[2] . "`n"
		MgShareNew%MgShareI% := MgShareV
		}
	if (MgShareBad != "")
		MgShareErr := "That code holds values this version does not accept, so nothing was changed:`n`n" . MgShareBad
	}

if (MgShareErr != "")
	{
	msgbox, 4144, DeepFish, %MgShareErr%
	return
	}

for MgShareI, MgShareF in MgShareFlds
	{
	MgShareK := MgShareF[2]
	%MgShareK% := MgShareNew%MgShareI%
	}

gosub, AstraMigrateColours
gosub, RefreshGuiFields
gosub, RefreshControlModes
gosub, CMRefresh
gosub, ShowSection
gosub, SaveSettings
MgCodeCue("✅ Code applied and saved")
settimer, MgShareStatusClear, -5000
return

;====================================================================================================;

MgShareStatusClear:
MgCodeCue("Paste minigame code here")
return

;====================================================================================================;

MgRestoreDefaults:
MgDefAlso := {FishBarColorTolerance: 1, PerfectGreenColor: 1, PerfectWhiteColor: 1}
for i, f in ProfileFields
	{
	if (f[1] != "Minigame" and f[1] != "Rods" and !MgDefAlso.HasKey(f[2]))
		continue
	key := f[2]
	%key% := (f[4] = "bool") ? (f[3] = "true") : f[3]
	}
gosub, RefreshGuiFields
gosub, RefreshControlModes
gosub, CMRefresh
gosub, ShowSection
gosub, SaveSettings
return

;====================================================================================================;

RefreshGuiFields:

for i, f in ProfileFields
	{
	key := f[2]
	type := f[4]
	val := %key%
	if (type = "bool")
		{
		chkval := val ? 1 : 0
		GuiControl, 1:, %key%, %chkval%
		}
	else if (type = "shakemode" or type = "controlmode" or type = "castmode" or type = "specialrod"
		or type = "remembrancemode" or type = "totemsel")
		{
		GuiControl, 1:ChooseString, %key%, %val%
		}
	else
		GuiControl, 1:, %key%, %val%
	}

TotemSelSanitize()
TotemListsRefresh()
gosub, RefreshSwatches
gosub, RefreshCameraLock

if (TargetSection != "")
	{
	gosub, ApplyCastModeLocks
	gosub, ShowSection
	}

return

;====================================================================================================;

SaveSettings:

Gui, Submit, NoHide
if (SectionBuilt.HasKey("Misc"))
	PogoHotkey := PogoHotkeyCtrl

BadFields := ""
for i, f in ProfileFields
	{
	var := f[2]
	type := f[4]
	if (type = "num")
		{
		val := %var%
		if val is not number
			BadFields .= var . "`n"
		}
	}
if (BadFields != "")
	{
	msgbox, 4144, DeepFish, One or more fields contain an invalid number and were not saved:`n`n%BadFields%
	return
	}

FileCopy, %ActiveProfileFile%, %ActiveProfileFile%.bak, 1

for i, f in ProfileFields
	{
	sec := f[1]
	key := f[2]
	type := f[4]
	val := %key%
	if (type = "bool")
		val := val ? "true" : "false"
	DstFile := (sec = "Aquarium" or sec = "Keeper" or sec = "Update" or sec = "Advanced" or sec = "Misc" or (TotemGlobal and sec = "Totem")) ? SettingsFile : ActiveProfileFile
	IniWrite, %val%, %DstFile%, %sec%, %key%
	}

HotkeyState := HotkeysArmed ? "On" : "Off"
if (StartStopKeyCtrl != StartStopKey)
	{
	Hotkey, % "$" . StartStopKey, , Off
	StartStopKey := StartStopKeyCtrl
	Hotkey, % "$" . StartStopKey, HotkeyToggle, %HotkeyState%
	}
if (ReloadKeyCtrl != ReloadKey)
	{
	Hotkey, % "$" . ReloadKey, , Off
	ReloadKey := ReloadKeyCtrl
	Hotkey, % "$" . ReloadKey, HotkeyReload, %HotkeyState%
	}
if (ExitKeyCtrl != ExitKey)
	{
	Hotkey, % "$" . ExitKey, , Off
	ExitKey := ExitKeyCtrl
	Hotkey, % "$" . ExitKey, HotkeyExit, %HotkeyState%
	}
IniWrite, %WebhookURL%, %SettingsFile%, Webhook, URL
WhVal := WebhookOn ? 1 : 0
IniWrite, %WhVal%, %SettingsFile%, Webhook, Enabled
WhVal := WebhookShot ? 1 : 0
IniWrite, %WhVal%, %SettingsFile%, Webhook, Screenshot
IniWrite, %WebhookSummaryMin%, %SettingsFile%, Webhook, SummaryMinutes
IniWrite, %WebhookStallMin%, %SettingsFile%, Webhook, StallMinutes
WhVal := WebhookOnCatch ? 1 : 0
IniWrite, %WhVal%, %SettingsFile%, Webhook, OnCatch
WhVal := WebhookOnAlert ? 1 : 0
IniWrite, %WhVal%, %SettingsFile%, Webhook, OnAlert
IniWrite, %StartStopKey%, %SettingsFile%, Hotkeys, StartStop
IniWrite, %ReloadKey%, %SettingsFile%, Hotkeys, Reload
IniWrite, %ExitKey%, %SettingsFile%, Hotkeys, Exit
gosub, PogoApplyHotkey

GuiControl, 1:, SaveStatusText, ✅ Saved
settimer, RestoreSaveButton, -1500
return

RestoreSaveButton:
GuiControl, 1:, SaveStatusText, 💾 Save

return

;====================================================================================================;

ProfileSelect:

GuiControlGet, NewProfileChoice, 1:, ProfileSelect
if (NewProfileChoice = "" or NewProfileChoice = ActiveProfile)
	return
ActiveProfile := NewProfileChoice
ActiveProfileFile := ProfilesDir . "\" . ActiveProfile . ".ini"
IniWrite, %ActiveProfile%, %SettingsFile%, Profiles, ActiveProfile
gosub, LoadActiveProfile
gosub, RefreshGuiFields
return

;====================================================================================================;

ProfileNew:

Gui, 1:-AlwaysOnTop
InputBox, NewProfileName, New Profile, Enter a name for the new profile:, , 300, 130
if (GuiAlwaysOnTop)
	Gui, 1:+AlwaysOnTop
if ErrorLevel
	return
NewProfileName := Trim(NewProfileName)
if (NewProfileName = "")
	return
if RegExMatch(NewProfileName, "[\\/:*?""<>|]")
	{
	msgbox, 4144, DeepFish, Profile names can't contain \ / : * ? " < > |
	return
	}
NewProfileFile := ProfilesDir . "\" . NewProfileName . ".ini"
if FileExist(NewProfileFile)
	{
	msgbox, 4144, DeepFish, A profile named "%NewProfileName%" already exists.
	return
	}
for i, f in ProfileFields
	{
	sec := f[1]
	key := f[2]
	def := f[3]
	IniWrite, %def%, %NewProfileFile%, %sec%, %key%
	}
ActiveProfile := NewProfileName
ActiveProfileFile := NewProfileFile
IniWrite, %ActiveProfile%, %SettingsFile%, Profiles, ActiveProfile
gosub, LoadActiveProfile
gosub, RefreshProfileList
gosub, RefreshGuiFields

return

;====================================================================================================;

ProfileDuplicate:

Gui, 1:-AlwaysOnTop
InputBox, NewProfileName, Duplicate Profile, Enter a name for the copy of "%ActiveProfile%":, , 320, 130
if (GuiAlwaysOnTop)
	Gui, 1:+AlwaysOnTop
if ErrorLevel
	return
NewProfileName := Trim(NewProfileName)
if (NewProfileName = "")
	return
if RegExMatch(NewProfileName, "[\\/:*?""<>|]")
	{
	msgbox, 4144, DeepFish, Profile names can't contain \ / : * ? " < > |
	return
	}
NewProfileFile := ProfilesDir . "\" . NewProfileName . ".ini"
if FileExist(NewProfileFile)
	{
	msgbox, 4144, DeepFish, A profile named "%NewProfileName%" already exists.
	return
	}
FileCopy, %ActiveProfileFile%, %NewProfileFile%
ActiveProfile := NewProfileName
ActiveProfileFile := NewProfileFile
IniWrite, %ActiveProfile%, %SettingsFile%, Profiles, ActiveProfile
gosub, LoadActiveProfile
gosub, RefreshProfileList
gosub, RefreshGuiFields

return

;====================================================================================================;

ProfileDelete:

ProfileCount := 0
Loop, Files, %ProfilesDir%\*.ini
	ProfileCount++
if (ActiveProfile = "Default")
	{
	msgbox, 4144, DeepFish, The Default profile can't be deleted.
	return
	}
if (ProfileCount <= 1)
	{
	msgbox, 4144, DeepFish, You can't delete the only remaining profile.
	return
	}
MsgBox, 4100, DeepFish, Delete profile "%ActiveProfile%"? This can't be undone.
IfMsgBox, No
	return
FileDelete, %ActiveProfileFile%
ActiveProfile := "Default"
ActiveProfileFile := DefaultProfileFile
IniWrite, %ActiveProfile%, %SettingsFile%, Profiles, ActiveProfile
gosub, LoadActiveProfile
gosub, RefreshProfileList
gosub, RefreshGuiFields

return

;====================================================================================================;


;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------

ColNorm(v) {
	t := Trim(v)
	if (t = "")
		return -1
	hadPrefix := false
	if (SubStr(t, 1, 1) = "#")
		{
		t := SubStr(t, 2)
		hadPrefix := true
		}
	else if (SubStr(t, 1, 2) = "0x" or SubStr(t, 1, 2) = "0X")
		{
		t := SubStr(t, 3)
		hadPrefix := true
		}
	if (RegExMatch(t, "^[0-9a-fA-F]{6}$"))
		{
		hv := "0x" . t
		return hv + 0
		}
	if (!hadPrefix and RegExMatch(t, "^[0-9]{1,8}$") and (t + 0) <= 0xFFFFFF)
		return t + 0        
	return -1
}

ColListToArray(str) {
	arr := []
	Loop, Parse, str, `,;| , %A_Space%%A_Tab%
		{
		cn := ColNorm(A_LoopField)
		if (cn >= 0)
			arr.Push(cn)
		}
	return arr
}

ColArrayToList(arr) {
	out := ""
	for i, v in arr
		out .= (out = "" ? "" : ", ") . Format("0x{:06X}", v)
	return out
}

ColListAdd(str, hex) {
	arr := ColListToArray(str)
	cn := ColNorm(hex)
	if (cn < 0)
		return ColArrayToList(arr)
	for i, v in arr
		{
		if (v = cn)
			return ColArrayToList(arr)
		}
	if (arr.MaxIndex() >= 9)
		return ColArrayToList(arr)
	arr.Push(cn)
	return ColArrayToList(arr)
}

ColListRemoveAt(str, idx) {
	arr := ColListToArray(str)
	if (idx < 1 or idx > arr.MaxIndex())
		return ColArrayToList(arr)
	arr.RemoveAt(idx)
	return ColArrayToList(arr)
}

CMStore(key, val) {
	global
	%key% := val
	CMSec := CMTargetSection[key]
	IniWrite, %val%, %ActiveProfileFile%, %CMSec%, %key%
	GuiControl, 1:, %key%, %val%
	gosub, RefreshSwatches
}

;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------

CMApplyTargets:
if (SpecialRod = "Tryhard Rod")
	CMTargetKeys := ["TryhardFishColors","TryhardBarColors","TryhardTrackColors","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
else if (SpecialRod = "Castbound")
	CMTargetKeys := ["CastboundFishColors","CastboundBarColors","CastboundTrackColors","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
else if (SpecialRod = "Stellarwave Melody")
	CMTargetKeys := ["StellarBarColors","StellarFishColors","StellarHeadColors","PerfectGreenColor","PerfectWhiteColor"]
else
	CMTargetKeys := ["FishColor","BarLeftColor","BarRightColor","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
CMSelOk := false
for CMSelI, CMSelK in CMTargetKeys
	{
	if (CMSelK = CMSel)
		CMSelOk := true
	}
if (!CMSelOk)
	CMSel := CMTargetKeys[1]
return

BuildColorManagerSection:

CMRowSw := []
CMRowTx := []
CMRowBt := []
CMNavH := {}

; ---- left: which color ----
hC := AddPanel(CARDX, 162, 218, 356)
CMCtrls.Push(hC)

Gui, Font, s8 Bold c%ColorMuted%, Segoe UI
Gui, Add, Text, x204 y174 w186 h16 HwndhC, COLOR
CMCtrls.Push(hC)
Gui, Font, s9 Norm c%ColorText%, Segoe UI

CMy := 196
Loop, 7
	{
	i := A_Index
	lb := (i <= CMTargetKeys.MaxIndex()) ? CMTargetLabel[CMTargetKeys[i]] : ""
	Gui, Add, Text, x196 y%CMy% w202 h28 +0x200 vCMNav%i% gCMNavClick HwndhCMN, %lb%
	CMCtrls.Push(hCMN)
	CMNavH[i] := hCMN
	CMy += 30
	}

Gui, Font, s9 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x204 y414 w186 h28 Center +0x100 +0x200 gCMPickAdd HwndhC, 🎯  Pick from screen  (F9)
CMCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 186, 28, 7)
Gui, Font, s9 Norm c%ColorText%, Segoe UI
Gui, Add, Text, x204 y446 w186 h28 Center +0x100 +0x200 gCMTypeAdd HwndhC, ＋  Type a hex value
CMCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorTextBGR}
RoundCtrl(hC, 186, 28, 7)
Gui, Font, s9 Norm c%ColorRed%, Segoe UI
Gui, Add, Text, x204 y478 w186 h28 Center +0x100 +0x200 gCMClearAll HwndhC, Clear this list
CMCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorRedBGR}
RoundCtrl(hC, 186, 28, 7)

; ---- right: the list ----
hC := AddPanel(418, 162, 326, 356)
CMCtrls.Push(hC)

Gui, Font, s11 Bold c%ColorAccent%, Segoe UI
Gui, Add, Text, x434 y176 w294 h22 vCMTitle HwndhC, Fish line
CMCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
Gui, Font, s9 Norm cFFFFFF, Segoe UI
Gui, Add, Text, x434 y200 w294 h56 vCMHint HwndhC,
CMCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: 0xFFFFFF}

Gui, Font, s9 Norm c%ColorText%, Segoe UI
CMy := 262
Loop, %CMRowMax%
	{
	ri := A_Index
	Gui, Add, Progress, x434 y%CMy% w40 h22 vCMSw%ri% HwndhCMS Background202020, 0
	CMCtrls.Push(hCMS)
	CMRowSw.Push(hCMS)
	Gui, Add, Text, x482 y%CMy% w160 h22 +0x200 vCMHex%ri% HwndhCMT, --
	CMCtrls.Push(hCMT)
	SpecialBrushes[hCMT] := {brush: hBrushCard, text: 0xFFFFFF}
	CMRowTx.Push(hCMT)
	Gui, Add, Text, x656 y%CMy% w26 h22 Center +0x100 +0x200 vCMDel%ri% gCMRowDelete HwndhCMB, ✕
	CMCtrls.Push(hCMB)
	SpecialBrushes[hCMB] := {brush: hBrushCard, text: ColorRedBGR}
	CMRowBt.Push(hCMB)
	CMy += 24
	}

Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
Gui, Add, Text, x434 y264 w294 h60 vCMEmpty HwndhC, Nothing picked for this one yet.`n`nUse "Pick from screen" and click the color in game.
CMCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorMutedBGR}

Gui, Font, s9 Norm c%ColorAccent%, Segoe UI
Gui, Add, Text, x434 y482 w294 h26 Center +0x100 +0x200 vCMCopyBtn gCMCopyBar HwndhC, ⇄  Copy to the other end
CMCtrls.Push(hC)
SpecialBrushes[hC] := {brush: hBrushCard, text: ColorAccentBGR}
RoundCtrl(hC, 294, 26, 7)

Gui, Font, s9 Norm c%ColorMuted%, Segoe UI
return

CMCopyBar:
if (CMSel = "BarLeftColor")
	CMStore("BarRightColor", BarLeftColor)
else if (CMSel = "BarRightColor")
	CMStore("BarLeftColor", BarRightColor)
gosub, ShowSection
return

;====================================================================================================;

CMNavClick:
CMIdx := SubStr(A_GuiControl, 6)
if (CMIdx >= 1 and CMIdx <= CMTargetKeys.MaxIndex())
	CMSel := CMTargetKeys[CMIdx]
gosub, CMRefresh
gosub, RepaintGui
return

CMRefresh:
gosub, CMApplyTargets
if (!CMNavH)
	return
Loop, 7
	{
	i := A_Index
	if (i > CMTargetKeys.MaxIndex())
		{
		GuiControl, 1:Hide, CMNav%i%
		continue
		}
	k := CMTargetKeys[i]
	h := CMNavH[i]
	if (k = CMSel)
		SpecialBrushes[h] := {brush: hBrushBG, text: ColorAccentBGR}
	else
		SpecialBrushes[h] := {brush: hBrushCard, text: ColorTextBGR}
	CMCnt := ColCount(%k%)
	GuiControl, 1:, CMNav%i%, % (k = CMSel ? "  ▸ " : "     ") . CMTargetLabel[k]
		. (CMCnt ? "      " . CMCnt : "      not set")
	GuiControl, 1:Show, CMNav%i%
	}
GuiControl, 1:, CMTitle, % CMTargetLabel[CMSel]
GuiControl, 1:, CMHint, % CMTargetHint[CMSel]
if (CMSel = "BarLeftColor")
	{
	GuiControl, 1:, CMCopyBtn, ⇄  Copy this list to Bar - right end
	GuiControl, 1:Show, CMCopyBtn
	}
else if (CMSel = "BarRightColor")
	{
	GuiControl, 1:, CMCopyBtn, ⇄  Copy this list to Bar - left end
	GuiControl, 1:Show, CMCopyBtn
	}
else
	GuiControl, 1:Hide, CMCopyBtn
CMList := ColListToArray(%CMSel%)
CMn := CMList.MaxIndex()
if (!CMn)
	CMn := 0
Loop, %CMRowMax%
	{
	ri := A_Index
	if (ri <= CMn)
		{
		hx := Format("0x{:06X}", CMList[ri])
		sw := SubStr(hx, 3)
		GuiControl, 1:+Background%sw%, CMSw%ri%
		GuiControl, 1:, CMHex%ri%, % hx . (ri = 1 ? "      (primary)" : "")
		GuiControl, 1:Show, CMSw%ri%
		GuiControl, 1:Show, CMHex%ri%
		GuiControl, 1:Show, CMDel%ri%
		}
	else
		{
		GuiControl, 1:Hide, CMSw%ri%
		GuiControl, 1:Hide, CMHex%ri%
		GuiControl, 1:Hide, CMDel%ri%
		}
	}
if (CMn = 0)
	GuiControl, 1:Show, CMEmpty
else
	GuiControl, 1:Hide, CMEmpty
return

CMRowDelete:
CMIdx := SubStr(A_GuiControl, 6)
CMStore(CMSel, ColListRemoveAt(%CMSel%, CMIdx))
gosub, ShowSection
return

CMClearAll:
CMStore(CMSel, "")
gosub, ShowSection
return

CMTypeAdd:
Gui, 1:+OwnDialogs
InputBox, CMTyped, Add color, Enter a hex color (for example 0xF1F1F1):, , 320, 130
if ErrorLevel
	return
CMTyped := Trim(CMTyped)
CMTest := ColListToArray(CMTyped)
if (!CMTest.MaxIndex())
	{
	msgbox, 4144, DeepFish, That is not a hex color. Use six hex digits, like 0xF1F1F1.
	return
	}
CMStore(CMSel, ColListAdd(%CMSel%, CMTest[1]))
gosub, ShowSection
return

CMPickAdd:
FreezeTarget := CMSel
FreezeMode := "add"
gosub, FreezePick
return

FreezePickHotkey:
if (FreezeActive)
	return
gosub, CMApplyTargets
FreezeTarget := CMSel
FreezeMode := "add"
gosub, FreezePick
return

OpenColorManager:
if (!ReadThisAccepted)
	{
	gosub, ReadThisLockedNotice
	return
	}
gosub, DisarmHotkeys
if (!WinExist("DeepFish BETA"))
	Gui, 1:Show
TargetSection := "Minigame"
MiniTab := "Colors"
gosub, ShowSection
return

;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------

FreezePick:
if (FreezeActive)
	return
FreezeActive := true
FreezePicked := ""

SysGet, FrzVX, 76
SysGet, FrzVY, 77
SysGet, FrzVW, 78
SysGet, FrzVH, 79
if (FrzVW < 1)
	{
	FrzVX := 0
	FrzVY := 0
	FrzVW := A_ScreenWidth
	FrzVH := A_ScreenHeight
	}

Gui, 1:Hide

if (hFullBM)
	{
	DllCall("DeleteObject", "Ptr", hFullBM)
	hFullBM := 0
	}
if (hFullMemDC)
	{
	DllCall("DeleteDC", "Ptr", hFullMemDC)
	hFullMemDC := 0
	}
hFrzScreenDC := DllCall("GetDC", "Ptr", 0, "Ptr")
hFullMemDC := DllCall("CreateCompatibleDC", "Ptr", hFrzScreenDC, "Ptr")
VarSetCapacity(FrzBMI, 40, 0)
NumPut(40, FrzBMI, 0, "UInt")
NumPut(FrzVW, FrzBMI, 4, "Int")
NumPut(-FrzVH, FrzBMI, 8, "Int")
NumPut(1, FrzBMI, 12, "UShort")
NumPut(32, FrzBMI, 14, "UShort")
NumPut(0, FrzBMI, 16, "UInt")
hFullBM := DllCall("CreateDIBSection", "Ptr", hFrzScreenDC, "Ptr", &FrzBMI, "UInt", 0, "Ptr*", pFullBits, "Ptr", 0, "UInt", 0, "Ptr")
DllCall("SelectObject", "Ptr", hFullMemDC, "Ptr", hFullBM)
DllCall("BitBlt", "Ptr", hFullMemDC, "Int", 0, "Int", 0, "Int", FrzVW, "Int", FrzVH
	, "Ptr", hFrzScreenDC, "Int", FrzVX, "Int", FrzVY, "UInt", 0x00CC0020)
DllCall("ReleaseDC", "Ptr", 0, "Ptr", hFrzScreenDC)
Gui, 1:Show, NoActivate

FrzWhat := CMTargetLabel.HasKey(FreezeTarget) ? CMTargetLabel[FreezeTarget] : FreezeTarget
gosub, FrzBuildMenu
if (!RobloxHwnd)
	gosub, ResolveRoblox
FrzMonL := 0
FrzMonT := 0
FrzMonW := A_ScreenWidth
FrzMonH := A_ScreenHeight
if (RobloxHwnd)
	{
	RobloxClientRect(RobloxHwnd, FrzRx, FrzRy, FrzRw, FrzRh)
	FrzRcx := FrzRx + (FrzRw // 2)
	FrzRcy := FrzRy + (FrzRh // 2)
	SysGet, FrzMonN, MonitorCount
	Loop, %FrzMonN%
		{
		SysGet, FrzM, Monitor, %A_Index%
		if (FrzRcx >= FrzMLeft and FrzRcx < FrzMRight and FrzRcy >= FrzMTop and FrzRcy < FrzMBottom)
			{
			FrzMonL := FrzMLeft
			FrzMonT := FrzMTop
			FrzMonW := FrzMRight - FrzMLeft
			FrzMonH := FrzMBottom - FrzMTop
			break
			}
		}
	}
FrzBW := FrzMonW - 220
if (FrzBW > 1060)
	FrzBW := 1060
if (FrzBW < 420)
	FrzBW := 420
FrzBX := FrzMonL + ((FrzMonW - FrzBW) // 2) - FrzVX
FrzBY := FrzMonT + 54 - FrzVY
FrzTX := FrzBX + 28
FrzTW := FrzBW - 56
Gui, Frz:New, +AlwaysOnTop -Caption +ToolWindow +HwndhFrzGui
Gui, Frz:Color, 000000
Gui, Frz:Margin, 0, 0
Gui, Frz:Add, Picture, x0 y0 w%FrzVW% h%FrzVH%, HBITMAP:%hFullBM%
FrzR1 := FrzBY + 22
FrzR2 := FrzBY + 62
FrzR3 := FrzBY + 92
FrzR4 := FrzBY + 122
Gui, Frz:Add, Progress, x%FrzBX% y%FrzBY% w%FrzBW% h158 Background0A0E16, 0
FrzExitW := 268
FrzHintW := FrzTW - FrzExitW
FrzExitX := FrzTX + FrzHintW
Gui, Frz:Font, s9 Bold cFF6B6B, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR1% w%FrzTW% h20 BackgroundTrans, ❄   SCREEN FROZEN
Gui, Frz:Font, s20 Bold cFF4D4D, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR2% w%FrzTW% h34 BackgroundTrans vFrzTitle, %FrzWhat%
Gui, Frz:Font, s10 Bold cFFD479, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR3% w%FrzTW% h22 BackgroundTrans vFrzMenuTx, %FrzMenu%
Gui, Frz:Font, s10 Norm c9FB4D0, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR4% w%FrzHintW% h24 BackgroundTrans vFrzCount, Click the color in game  ·  number keys switch
Gui, Frz:Font, s10 Bold cFF4D4D, Segoe UI
Gui, Frz:Add, Text, x%FrzExitX% y%FrzR4% w%FrzExitW% h24 BackgroundTrans, Right-click or Esc to finish
Gui, Frz:Show, x%FrzVX% y%FrzVY% w%FrzVW% h%FrzVH%, DeepFishFreeze

LoupeSrc := 25
LoupeZoom := 7
LoupeImgW := LoupeSrc * LoupeZoom
LoupeW := LoupeImgW + 12
LoupeH := LoupeImgW + 12 + 28
Gui, Loupe:New, +AlwaysOnTop -Caption +ToolWindow +E0x8000020 +HwndhLoupeGui
Gui, Loupe:Color, 0B0E14
Gui, Loupe:Margin, 0, 0
Gui, Loupe:Show, x0 y0 w%LoupeW% h%LoupeH% NoActivate, DeepFishLoupe
hLoupeRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", LoupeW+1, "Int", LoupeH+1, "Int", 12, "Int", 12, "Ptr")
DllCall("SetWindowRgn", "Ptr", hLoupeGui, "Ptr", hLoupeRgn, "Int", true)

hLoupeDC := DllCall("GetDC", "Ptr", hLoupeGui, "Ptr")
hLoupeMem := DllCall("CreateCompatibleDC", "Ptr", hLoupeDC, "Ptr")
hLoupeBM := DllCall("CreateCompatibleBitmap", "Ptr", hLoupeDC, "Int", LoupeW, "Int", LoupeH, "Ptr")
hLoupeOldBM := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hLoupeBM, "Ptr")
DllCall("ReleaseDC", "Ptr", hLoupeGui, "Ptr", hLoupeDC)
hLoupeFont := DllCall("CreateFont", "Int", -14, "Int", 0, "Int", 0, "Int", 0, "Int", 700
	, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 1, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "Str", "Consolas", "Ptr")

CoordMode, Mouse, Screen
FrzCancelled := false
FrzAdded := 0
FrzForceZ := true
Loop
	{
	if (KeyHeld("Escape") or KeyHeld("RButton"))
		{
		FrzCancelled := (FrzAdded = 0)
		while KeyHeld("RButton")
			Sleep, % Tm(5)
		break
		}
	FrzSwitch := 0
	Loop, % CMTargetKeys.MaxIndex()
		{
		if (A_Index <= 9 and KeyHeld(A_Index))
			{
			FrzSwitch := A_Index
			break
			}
		}
	if (FrzSwitch)
		{
		while KeyHeld(FrzSwitch)
			Sleep, % Tm(5)
		FreezeTarget := CMTargetKeys[FrzSwitch]
		CMSel := FreezeTarget
		FrzWhat := CMTargetLabel[FreezeTarget]
		FrzAdded := 0
		gosub, FrzBuildMenu
		GuiControl, Frz:, FrzTitle, %FrzWhat%
		GuiControl, Frz:, FrzMenuTx, %FrzMenu%
		GuiControl, Frz:, FrzCount, % FrzWhat . " already has " . ColCount(%FreezeTarget%) . "  ·  click to add more"
		FrzForceZ := true
		}
	MouseGetPos, FrzMx, FrzMy
	FreezePaintLoupe(FrzMx, FrzMy, FrzForceZ)
	FrzForceZ := false
	if KeyHeld("LButton")
		{
		while KeyHeld("LButton")
			Sleep, % Tm(5)
		FrzForceZ := true
		FrzHex := FreezePixelAt(FrzMx, FrzMy)
		if (FrzHex != "" and FreezeTarget != "")
			{
			FrzBefore := ColCount(%FreezeTarget%)
			if (FreezeMode = "add")
				CMStore(FreezeTarget, ColListAdd(%FreezeTarget%, FrzHex))
			else
				CMStore(FreezeTarget, FrzHex)
			FrzAfter := ColCount(%FreezeTarget%)
			FreezePicked := FrzHex
			if (FrzAfter > FrzBefore)
				{
				FrzAdded := FrzAdded + 1
				GuiControl, Frz:, FrzCount, % "added " . FrzAdded . "   (" . FrzAfter . " on this color)   last " . FrzHex
				}
			else
				GuiControl, Frz:, FrzCount, % "added " . FrzAdded . "   " . FrzHex . " was already in the list"
			}
		}
	Sleep, % Tm(12)
	}
CoordMode, Mouse, Client

Gui, Loupe:Destroy
Gui, Frz:Destroy
Gui, 1:Default
Gui, 1:Show
if (hLoupeMem)
	{
	if (hLoupeOldBM)
		DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hLoupeOldBM)
	DllCall("DeleteDC", "Ptr", hLoupeMem)
	hLoupeMem := 0
	hLoupeOldBM := 0
	}
if (hLoupeBM)
	{
	DllCall("DeleteObject", "Ptr", hLoupeBM)
	hLoupeBM := 0
	}
if (hLoupeFont)
	{
	DllCall("DeleteObject", "Ptr", hLoupeFont)
	hLoupeFont := 0
	}
FreezeActive := false

TargetSection := "Minigame"
MiniTab := "Colors"
gosub, ShowSection
return

FrzBuildMenu:
FrzMenu := ""
for FrzI, FrzK in CMTargetKeys
	FrzMenu .= (FrzMenu = "" ? "" : "     ")
		. ((FrzK = FreezeTarget) ? "▸ " : "") . FrzI . " " . CMShortLabel[FrzK]
return

FreezePixelAt(sx, sy) {
	global pFullBits, FrzVX, FrzVY, FrzVW, FrzVH
	x := sx - FrzVX
	y := sy - FrzVY
	if (x < 0 or y < 0 or x >= FrzVW or y >= FrzVH)
		return ""
	v := NumGet(pFullBits + 0, (y*FrzVW*4) + (x*4), "UInt")
	return Format("0x{:02X}{:02X}{:02X}", (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
}

FreezePaintLoupe(sx, sy, force := false) {
	global hLoupeGui, hLoupeMem, hLoupeFont, hFullMemDC, pFullBits
	global LoupeSrc, LoupeZoom, LoupeImgW, LoupeW, LoupeH
	global FrzVX, FrzVY, FrzVW, FrzVH
	static lastX := -99999, lastY := -99999, lastZ := 0
	if (!hLoupeMem)
		return
	px := sx - FrzVX
	py := sy - FrzVY
	half := LoupeSrc // 2

	DllCall("SetBkMode", "Ptr", hLoupeMem, "Int", 1)
	brBG := DllCall("CreateSolidBrush", "UInt", 0x140E0B, "Ptr")
	VarSetCapacity(rc, 16, 0)
	NumPut(0, rc, 0, "Int"), NumPut(0, rc, 4, "Int"), NumPut(LoupeW, rc, 8, "Int"), NumPut(LoupeH, rc, 12, "Int")
	DllCall("FillRect", "Ptr", hLoupeMem, "Ptr", &rc, "Ptr", brBG)
	DllCall("DeleteObject", "Ptr", brBG)

	sx0 := px - half
	sy0 := py - half
	if (sx0 < 0)
		sx0 := 0
	if (sy0 < 0)
		sy0 := 0
	if (sx0 > FrzVW - LoupeSrc)
		sx0 := FrzVW - LoupeSrc
	if (sy0 > FrzVH - LoupeSrc)
		sy0 := FrzVH - LoupeSrc
	DllCall("SetStretchBltMode", "Ptr", hLoupeMem, "Int", 3)
	DllCall("StretchBlt", "Ptr", hLoupeMem, "Int", 6, "Int", 6, "Int", LoupeImgW, "Int", LoupeImgW
		, "Ptr", hFullMemDC, "Int", sx0, "Int", sy0, "Int", LoupeSrc, "Int", LoupeSrc, "UInt", 0x00CC0020)
	cpx := (px - sx0)
	cpy := (py - sy0)
	if (cpx < 0)
		cpx := 0
	if (cpy < 0)
		cpy := 0

	cx := 6 + (cpx * LoupeZoom)
	cy := 6 + (cpy * LoupeZoom)
	penW := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", 0xFFFFFF, "Ptr")
	penK := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", 0x000000, "Ptr")
	hollow := DllCall("GetStockObject", "Int", 5, "Ptr")
	oldBr := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hollow, "Ptr")
	oldPen := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", penK, "Ptr")
	DllCall("Rectangle", "Ptr", hLoupeMem, "Int", cx-2, "Int", cy-2, "Int", cx+LoupeZoom+2, "Int", cy+LoupeZoom+2)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", penW)
	DllCall("Rectangle", "Ptr", hLoupeMem, "Int", cx-1, "Int", cy-1, "Int", cx+LoupeZoom+1, "Int", cy+LoupeZoom+1)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", oldPen)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", oldBr)
	DllCall("DeleteObject", "Ptr", penW)
	DllCall("DeleteObject", "Ptr", penK)

	hex := FreezePixelAt(sx, sy)
	if (hex = "")
		hex := "0x000000"
	sr := "0x" . SubStr(hex, 3, 2)
	sg := "0x" . SubStr(hex, 5, 2)
	sb := "0x" . SubStr(hex, 7, 2)
	swBGR := (sb << 16) | (sg << 8) | sr
	brSw := DllCall("CreateSolidBrush", "UInt", swBGR, "Ptr")
	NumPut(6, rc, 0, "Int"), NumPut(LoupeImgW + 10, rc, 4, "Int")
	NumPut(34, rc, 8, "Int"), NumPut(LoupeImgW + 32, rc, 12, "Int")
	DllCall("FillRect", "Ptr", hLoupeMem, "Ptr", &rc, "Ptr", brSw)
	DllCall("DeleteObject", "Ptr", brSw)

	oldFont := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hLoupeFont, "Ptr")
	DllCall("SetTextColor", "Ptr", hLoupeMem, "UInt", 0xF7F1EE)
	NumPut(40, rc, 0, "Int"), NumPut(LoupeImgW + 10, rc, 4, "Int")
	NumPut(LoupeW - 6, rc, 8, "Int"), NumPut(LoupeImgW + 32, rc, 12, "Int")
	DllCall("DrawText", "Ptr", hLoupeMem, "Str", hex, "Int", -1, "Ptr", &rc, "UInt", 0x24)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", oldFont)

	hdc := DllCall("GetDC", "Ptr", hLoupeGui, "Ptr")
	DllCall("BitBlt", "Ptr", hdc, "Int", 0, "Int", 0, "Int", LoupeW, "Int", LoupeH
		, "Ptr", hLoupeMem, "Int", 0, "Int", 0, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", hLoupeGui, "Ptr", hdc)

	lx := sx + 26
	ly := sy + 26
	if (lx + LoupeW > FrzVX + FrzVW)
		lx := sx - LoupeW - 26
	if (ly + LoupeH > FrzVY + FrzVH)
		ly := sy - LoupeH - 26
	if (force or lx != lastX or ly != lastY or A_TickCount - lastZ >= 100)
		{
		lastX := lx
		lastY := ly
		lastZ := A_TickCount
		DllCall("SetWindowPos", "Ptr", hLoupeGui, "Ptr", -1, "Int", lx, "Int", ly, "Int", 0, "Int", 0, "UInt", 0x0211)
		}
}

;====================================================================================================;

ClearIconTip:
MouseGetPos, , , , HoverCtrlHwnd, 2
if (!IconTips.HasKey(HoverCtrlHwnd))
	{
	ToolTip, , , , 3
	SetTimer, ClearIconTip, Off
	}
return

;====================================================================================================;

ColorFieldChanged:
ColFieldName := A_GuiControl
if (InStr(",PerfectGreenColor,PerfectWhiteColor,FishColor,NoteColor,BarLeftColor,BarRightColor,ArrowColor,TryhardBarColors,TryhardFishColors,TryhardTrackColors,CastboundBarColors,CastboundFishColors,CastboundTrackColors,StellarBarColors,StellarFishColors,StellarHeadColors,", "," . ColFieldName . ","))
	{
	GuiControlGet, ColFieldVal, 1:, %ColFieldName%
	if (!ErrorLevel)
		%ColFieldName% := ColFieldVal
	}
gosub, RefreshSwatches
gosub, QueueAutoSave
return

QueueAutoSave:
if (GuiAutoSave)
	settimer, AutoSaveNow, -1200
return

AutoSaveNow:
if (!GuiAutoSave)
	return
gosub, SaveSettings
return

RefreshSwatches:
SwFish := Format("{:06X}", ColMain(FishColor))
if (!ColCount(FishColor))
	SwFish := "202020"
GuiControl, 1:+Background%SwFish%, FishColorSwatch
SwNote := Format("{:06X}", ColMain(NoteColor))
if (!ColCount(NoteColor))
	SwNote := "202020"
GuiControl, 1:+Background%SwNote%, NoteColorSwatch
SwLeft := Format("{:06X}", ColMain(BarLeftColor))
if (!ColCount(BarLeftColor))
	SwLeft := "202020"
GuiControl, 1:+Background%SwLeft%, BarLeftColorSwatch
SwRight := Format("{:06X}", ColMain(BarRightColor))
if (!ColCount(BarRightColor))
	SwRight := "202020"
GuiControl, 1:+Background%SwRight%, BarRightColorSwatch
SwArrow := Format("{:06X}", ColMain(ArrowColor))
if (!ColCount(ArrowColor))
	SwArrow := "202020"
GuiControl, 1:+Background%SwArrow%, ArrowColorSwatch
SwCastG := Format("{:06X}", ColMain(PerfectGreenColor))
if (!ColCount(PerfectGreenColor))
	SwCastG := "202020"
GuiControl, 1:+Background%SwCastG%, CastGreenSwatch
SwCastW := Format("{:06X}", ColMain(PerfectWhiteColor))
if (!ColCount(PerfectWhiteColor))
	SwCastW := "202020"
GuiControl, 1:+Background%SwCastW%, CastWhiteSwatch
for SwI, SwK in ["TryhardBarColors","TryhardFishColors","TryhardTrackColors","CastboundBarColors","CastboundFishColors","CastboundTrackColors","StellarBarColors","StellarFishColors","StellarHeadColors"]
	{
	SwV := Format("{:06X}", ColMain(%SwK%))
	if (!ColCount(%SwK%))
		SwV := "202020"
	GuiControl, 1:+Background%SwV%, %SwK%Swatch
	}
return

;====================================================================================================;


;====================================================================================================;

ClearDumpTip:
tooltip, , , , 3
return

ToggleAlwaysOnTop:
GuiControlGet, GuiAlwaysOnTop,, GuiAlwaysOnTop
if (GuiAlwaysOnTop)
	Gui, +AlwaysOnTop
else
	Gui, -AlwaysOnTop
IniWrite, %GuiAlwaysOnTop%, %SettingsFile%, GUI, AlwaysOnTop
return

ToggleKeepOpen:
GuiControlGet, GuiKeepOpen,, GuiKeepOpen
IniWrite, %GuiKeepOpen%, %SettingsFile%, GUI, KeepOpen
return

ToggleAutoSave:
GuiControlGet, GuiAutoSave, 1:, GuiAutoSave
IniWrite, %GuiAutoSave%, %SettingsFile%, GUI, AutoSave
if (GuiAutoSave)
	gosub, SaveSettings
return

RevertSettings:
if !FileExist(ActiveProfileFile . ".bak")
	{
	GuiControl, 1:, SaveStatusText, ↶ none
	settimer, RestoreSaveButton, -1500
	return
	}
FileCopy, %ActiveProfileFile%.bak, %ActiveProfileFile%, 1
gosub, LoadActiveProfile
gosub, RefreshGuiFields
gosub, RefreshSwatches
GuiControl, 1:, SaveStatusText, ↶ undone
settimer, RestoreSaveButton, -1500
return

ShowGuiFromTray:
gosub, DisarmHotkeys
Gui, Show
return

GuiClose:
gosub, DoExit
return

ShellMin:
WinMinimize, ahk_id %GuiHwnd%
return

ShellClose:
gosub, GuiClose
return

GuiEscape:
return