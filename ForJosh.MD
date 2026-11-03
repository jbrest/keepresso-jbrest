# Keepresso and Sleepless Hollow

Josh,

I'd welcome your thoughts on a project that started with a small need on my
headless Mac Studio and has grown into something more substantial. I'd also be
interested to know whether any part of it appeals to you enough to get
involved.

## How it started

I found **Keepresso**, an open-source Mac menu-bar app that keeps a Mac awake
manually or when conditions match, such as a running process, CPU load or
network activity. It seemed a good starting point for what I wanted, and might
suit your Studio too as an alternative to keeping it awake whenever it is on
AC power.

The main need is reliable **remote VS Code access and SSH**, including
recovery following a reboot. I don't normally log into the Studio at a
physical console -- and also not even usually with Screen Sharing -- so
keeping it reachable shouldn't depend on a desktop login or a configuration
app staying open. I want it to stay awake when selected conditions apply,
rather than simply leave it awake all the time.

After a reboot, the service should resume once FileVault is unlocked and macOS
starts; sadly, there is no way to bypass FileVault. A logged-in desktop
session could also be a reason to stay awake after I disconnect Screen
Sharing, but remote development and SSH are the main motivation.

Initially, we (me, Claude Code, and Codex, that is -- not the royal "we")
added a headless mode to Keepresso and built and tested a first version. But
combining its desktop rules with machine-wide background rules made the
interface look like 💩 and service management unnecessarily awkward. I decided
a separate application would make more sense.

Its working name is **Sleepless Hollow**: a configuration app and a background
service that enforces the policy independently of the app or a desktop login.
The standalone interface is still being designed.

## Why refactor Keepresso?

Rather than copy the code and maintain two increasingly different versions, I
thought there might be something useful to contribute back. Keepresso already
separates its UI from its core, but much of the reusable functionality lives
together in one large core library. Extracting smaller modules with clear
responsibilities would make it practical for two applications to share that
functionality without each depending on the rest of the other application.

I'm in the middle of extracting shared components for observing system state
and evaluating conditions, with power control and service management to
follow.

Keepresso uses the extracted code through adapters that preserve its existing
functionality and UI. Sleepless Hollow can use the same foundation with its
own configuration, handling of unavailable readings and service lifecycle. All
this work is in my fork; it doesn't change Gyorgy's project.

## The options with Gyorgy

Gyorgy maintains Keepresso, so he decides what, if anything, he wants to
adopt. The first question is whether he likes the modularization:

- **If he does, he could adopt the refactoring and continue maintaining
  Keepresso.** Sleepless Hollow could use the shared components from a
  separate repository, with its own releases. We wouldn't have to make every
  product decision together or adopt each other's changes immediately.
- **He might also want to maintain Sleepless Hollow's frontend.** Its
  configuration interface should be fairly small, so he might find it a
  natural companion to Keepresso. I'd welcome that, but otherwise I'll take
  responsibility for it. The background service still needs its own testing
  and maintenance; a small interface doesn't make that work disappear.
- **If he isn't interested, I'll keep the modular approach I've already
  implemented in my own fork.** I'll preserve attribution and the applicable
  license, watch his PRs and releases for important fixes, and decide which
  changes to incorporate. I can still offer useful work back without asking
  him to adopt the overall redesign.

His participation isn't a prerequisite for the functionality I want, and I
wouldn't expect him to maintain another application or integrate a rewrite for
me. My intention is to do work primarily for my own needs and offer him
something concrete and reviewed if it interests him.

## Where testing stands

The initial extraction of power-source, schedule, CPU, network-throughput and
process functionality is implemented. At the recorded Stage A checkpoint, all
**1,177 original tests** were retained and the expanded suite passed **1,233
tests**. Package and application builds also passed. Installed service
behavior still needs separate validation.

I've completed the first hands-on SSH testing sitting with Claude Code, using
my MacBook to connect to the Studio. This examines ordinary connections,
connections before authentication, different SSH uses and what happens when
the network disappears without a clean disconnect. Early runs exposed problems
in the test scripts and capture tools, so affected evidence needs checking or
repeating before drawing conclusions. The intended behavior is to keep the Mac
awake while an incoming SSH connection is being established, including while
someone is authenticating. The testing is about detecting and tracking those
connections reliably, including when they disappear without closing cleanly.

Next are Screen Sharing, locking, switching users and separate desktop
sessions. Logout, reboot, operation with nobody logged in and the actual power
mechanism come later under a reviewed test plan. Session prototypes exist, but
live SSH detection isn't yet enabled as a supported feature. The complete
standalone application and service are still to be built.

## Your thoughts?

I'm directing the product and doing the hands-on testing. Codex is doing much
of the design, implementation and automated validation, with Claude Code
reviewing the work and helping develop and run the tests. I'd value an
independent human perspective too.

Does separating the applications make sense? Do you see a better approach to
sharing the code or discussing it with Gyorgy? And would you have any interest
in reviewing the architecture or code, helping with testing, or getting
involved more substantially? Comments alone would be welcome; there's no
assumed commitment.

Dad
