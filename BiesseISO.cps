/*
    Post processor for Autodesk Fusion to Biesse ISO format (for Rover and Multi machines)

    Copyright 2026 cnc-axis

    This code is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International
    license, with the following additions. By exercising the Licensed Rights in the above license, you accept and 
    agree to be bound by the terms and conditions both in that license and in the Additional Terms below.
    
    To view a copy of the CC-BY-NC-ND license, visit https://creativecommons.org/licenses/by-nc-nd/4.0/
    
    Additional terms:
    
    1. You agree that the output of this post processor will not be used to operate a CNC machine.
    2. You agree that the licensor will in no event by liable to you or any third party for any loss, damage or injury, including
    any damage to a physical or virtual CNC machine, workpiece, CNC machine warranty arising from the 
    use of this post processor. 
*/

// Debug settings
// debugMode = true;
// setWriteInvocations(true); 

// Header/global variables
description = "Biesse Rover / Multi (ISO format)";
vendor = "cnc-axis";
vendorUrl = "https://github.com/cnc-axis";
legal = "Licensed under CC-BY-NC-ND license with additions described in the source code.";
certificationLevel = 2; // Magic number supplied by Autodesk
minimumRevision = 50231; // Magic number supplied by Autodesk - oldest compatible version of their post framework

longDescription = "Not for commercial use. Post processed files are for simulation only and may not be run on a physical CNC machine";

extension = "iso"; // File extension for BSuite = *.iso
setCodePage("ascii"); // Autodesk magic that every other post does

// Kernel settings (used by the post engine)
capabilities = CAPABILITY_MILLING;

// Kernel settings - circular interpolation
allowedCircularPlanes = undefined; // (1 << PLANE_XY); // According to CNI docs, only XY plane is supported for interpolation. 
allowHelicalMoves = false; // Helical moves will be linearized
allowSpiralMoves = false; // Spiral moves will be linearized 

circularInputTolerance = 3; // Disable conversion of spiral/helical move to circular below a tolerance. 
circularMergeTolerance = 0; // Disable merging of consecutive circular records
minimumCircularRadius = spatial(0.01, MM); // rs274 post processor default
maximumCircularRadius = spatial(10000, MM); // Increased from rs274 default of 1000, to allow for wider arcs
minimumCircularSweep = toRad(0.01); // rs274 default
maximumCircularSweep = toRad(360); // Increased from rs274 default of 180 degrees
minimumChordLength = spatial(0.1, MM); // Decreaed from rs274 default of 0.25mm

// Circular moves smaller than this will be linearized. Same setting as rs274.
// Any circular move not supported by the controller will be linearised using this tolerance. 
// See rs274 for other global variables relating to circular moves
tolerance = spatial(0.002, MM); 

// User-defined properties
groupDefinitions = {
    positioning: {
        title: "Workpiece positioning",
        description: "Position of workpiece in the machine",
        collapsed: false
    },
    extractor: {
        title: "Dust extractor hood",
        description: "WARNING - Incorrect settings will damage the hood. Use at own risk and check in simulator.",
        collapsed: false
    },
    workholding: {
        title: "Workholding (pods and rails)",
        description: "Panel lift, pod, rail, Uniclamp settings"
    }
}

properties = {
    // Positioning and table tooling properties
    stopsRow: {
        title: "Row of stops to use for workpiece positioning",
        description: "The row of workpiece positioning stops to raise when the program starts",
        group: "positioning",
        type: "enum",
        value: "0",
        values: [
            { title: "0 (Operator chooses on machine)", id: "0" },
            { title: "1 (Back row - positions 1-4)", id: "1" },
            { title: "2 (Middle row - positions 5-8)", id: "2" },
            { title: "3 (Front row - positions 9-12)", id: "3" }
        ],
        scope: "post"
    },
    
    xOffset: {
        title: "X offset (positive X points right)",
        description: "Add this X offset to the workpiece origin",
        group: "positioning",
        type: "spatial",
        value: 0,
        scope: "post"
    },

    yOffset: {
        title: "Y offset (positive Y points towards back of machine)",
        description: "Add this Y offset to the workpiece origin",
        group: "positioning",
        type: "spatial",
        value: 0,
        scope: "post"
    },

    zOffset: {
        title: "Z offset (positive Z points up)",
        description: "Use a negative offset for shorter pods, or a positive offset if using a fixture/backerboard",
        group: "positioning",
        type: "spatial",
        value: 0,
        scope: "post"
    },

    enableVacuumAllRails: {
        title: "Enable vacuum pods on all rails (left and right side of work table)",
        description: "For pieces below a set width (x-size), the machine will normally enable only the left or right set of vacuum pods. Use this to override the machine and always enable all pods.",
        group: "positioning",
        type: "enum",
        value: "0",
        values: [
            { title: "(Machine default) The CNC controller decides whether to enable left, right, or both sets of rails.", id: "0" },
            { title: "Enable vacuum on all pods and rails", id: "1" }
        ],
        scope: "post"
    },

    // Dust extractor properties
    chipBlowerActivated: {
        title: "Chip clearing blower",
        description: "Use the compressed air blower mounted near the spindle to help clear machining waste.",
        group: "extractor",
        type: "boolean",
        value: false,
        scope: "post"
    },

    hoodPosition3Axis: {
        title: "Extractor hood height (3 axis program sections)",
        description: "Use at own risk of collision.",
        group: "extractor",
        type: "enum",
        value: "10",
        values: [
            { title: "Distance above workpiece", id: "distanceAboveWorkpiece"},
            { title: "From end of tool", id: "offsetFromEndOfTool" },
            { title: "1 (highest and safest)", id: "1" },
            { title: "2", id: "2" },
            { title: "3", id: "3" },
            { title: "4", id: "4" },
            { title: "5", id: "5" },
            { title: "6 (medium height)", id: "6" },
            { title: "7", id: "7" },
            { title: "8", id: "8" },
            { title: "9", id: "9" },
            { title: "10", id: "10" },
            { title: "11", id: "11" },
            { title: "12 (lowest)", id: "12" }
        ],
        scope: "post"  
    },

    distanceAboveWorkpiece: {
        title: "('Distance above workpiece' mode only) Minimum height offset above workpiece",
        description: "Height of extractor hood relative to the end of the tool - used when 'From end of tool' is selected. Use at own risk of collision.",
        group: "extractor",
        type: "spatial",
        value: 5,
        range: [-5, 100]
    },


    hoodOffsetFromToolEnd3Axis: {
        title: "('From end of tool' mode only) Height offset from end of tool",
        description: "Height of extractor hood relative to the end of the tool - used when 'From end of tool' is selected. Use at own risk of collision.",
        group: "extractor",
        type: "spatial",
        value: 25,
        range: [0, 250]
    },

    hoodPosition5Axis: {
        title: "Extractor hood height (5 axis program sections)",
        description: "Use at own risk. 5 axis programs may damage the hood. If in doubt, set to 1 (highest and safest).  Use at own risk of collision.",
        group: "extractor",
        type: "enum",
        value: "6",
        values: [
            { title: "1 (highest and safest)", id: "1" },
            { title: "2", id: "2" },
            { title: "3", id: "3" },
            { title: "4", id: "4" },
            { title: "5", id: "5" },
            { title: "6 (medium height)", id: "6" },
            { title: "7", id: "7" },
            { title: "8", id: "8" },
            { title: "9", id: "9" },
            { title: "10", id: "10" },
            { title: "11", id: "11" },
            { title: "12 (lowest)", id: "12" }
        ],
        scope: "post"  
    },

    panelLiftingBars: {
        title: "Panel lifting bars",
        description: "Use panel lifting bars to load and unload the workpiece",
        group: "workholding",
        type: "enum",
        value: "0",
        values: [
            { title: "Operator chooses on machine (default", id: "0" },
            { title: "Do not raise the lifting bars", id: "1" },
            { title: "Raise the lifting bars", id: "2" }
        ],
        scope: "post"  
    },

    // Sequence number properties taken from rs274 post.
    // writeBlock() depends on these, so they are included so that the original writeBlock() function can be used
    showSequenceNumbers: {
        title: "Use sequence numbers",
        description: "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
        group: "formats",
        type: "enum",
        values: [
            { title: "Yes", id: "true" },
            { title: "No", id: "false" },
            { title: "Only on tool change", id: "toolChange" }
        ],
        value: "true",
        scope: "post",
        visible: false
    },
    sequenceNumberStart: {
        title: "Start sequence number",
        description: "The number at which to start the sequence numbers.",
        group: "formats",
        type: "integer",
        value: 10,
        scope: "post",
        visible: false
    },
    sequenceNumberIncrement: {
        title: "Sequence number increment",
        description: "The amount by which the sequence number is incremented by in each block.",
        group: "formats",
        type: "integer",
        value: 5,
        scope: "post",
        visible: "false"
    },
}

// Fixed settings
var settings = {
    // Set all coolants explicitly to 'off', although they default to off.
    coolants: [
        {id:COOLANT_FLOOD},
        {id:COOLANT_MIST},
        {id:COOLANT_THROUGH_TOOL},
        {id:COOLANT_AIR},
        {id:COOLANT_AIR_THROUGH_TOOL},
        {id:COOLANT_SUCTION},
        {id:COOLANT_FLOOD_MIST},
        {id:COOLANT_FLOOD_THROUGH_TOOL},
        {id:COOLANT_OFF}
      ],
 
      // TODO - toolList/writeToolList - these write a header in the NC file with the list of tools.
      // Write these to a [UTENSILI] section so that the simulator/machine can check all the needed tools are present
      // before starting the program.
 
    // comments settings taken from rs274 post and altered to use semicolon
    comments: {
        permittedCommentChars: " abcdefghijklmnopqrstuvwxyz0123456789.,=_-!@#$%^&*+|/?<>[]{};:'\"", // letters are not case sensitive, use option 'outputFormat' below. Set to 'undefined' to allow any character
        prefix               : ";", // specifies the prefix for the comment
        suffix               : "", // specifies the suffix for the comment
        outputFormat         : "ignoreCase", // can be set to "upperCase", "lowerCase" and "ignoreCase". Set to "ignoreCase" to write comments without upper/lower case formatting
        maximumLineLength    : 120 // the maximum number of characters allowed in a line, set to 0 to disable comment output
      },
    ////
    
// Docs say 'Set to false if the rotary axes position should be used for 3+2 operations
    workPlaneMethod: {
        useTiltedWorkplane: false
    },
    maximumSpindleRPM: 20000, // Hardcoded for Biesse Rover A. TODO - may not be necessary as program will be validated by BSolid
    outputToolDiameterOffset: false 
}

//// Internal variables, taken from rs274 post
// twp = tilted work plane - see p4-87
var sequenceNumber; // Used to store the current sequence number, if any
var optionalSection = false; // Used in onSection() - set to currentSection.isOptional()
var skipBlocks = false;
var pendingRadiusCompensation = -1;

var tcp = {isSupportedByControl:getSetting("supportsTCP", true), isSupportedByMachine:false, isSupportedByOperation:false};
var state = {
  retractedX              : false, // specifies that the machine has been retracted in X
  retractedY              : false, // specifies that the machine has been retracted in Y
  retractedZ              : false, // specifies that the machine has been retracted in Z
  tcpIsActive             : false, // specifies that TCP is currently active
  twpIsActive             : false, // specifies that TWP is currently active
  lengthCompensationActive: !getSetting("outputToolLengthCompensation", true), // specifies that tool length compensation is active
  mainState               : true // specifies the current context of the state (true = main, false = optional)
};

//// Formats and output variables from RS274 post except where noted

// Formats

// y and z formats flipped, decimals set to 3 (BSolid post output uses 5)
var xFormat = createFormat({decimals:3});
var yFormat = undefined; // Set this up in onOpen(), because we need the workpiece dimensions to set the offset.
var zFormat = createFormat({decimals:3, scale:-1});

// ij format created because reference code used xyzFormat, which was separated out
// Number of decimals set to 3 to reduce the chance of BSolid rejecting arcs over small floating point inaccuracies.
var iFormat = createFormat({decimals:3});
var jFormat = undefined; // Assigned in onOpen()

// General format for variables such as those used in PARAMETRI blocks
var threeDecimalFormat = createFormat({decimals:3});
var intOutput = createFormat({decimals:0});
var abcFormat = createFormat({decimals:3, type:FORMAT_REAL, scale:DEG}); // Biesse iso format is different, forces decimal output

var gFormat = createFormat({prefix:"G", decimals:1, minDigitsLeft:1});
var mFormat = createFormat({prefix:"M", decimals:1});
var rpmFormat = createFormat({decimals:0});

// [ Different from RS274 post ] Feed format is scaled by 0.001 because the machine expects m/min and Fusion outputs mm/min
var feedFormat = createFormat({decimals:(unit == MM ? 3 : 1), scale:(unit == MM ? 0.001 : 1)});

// Output variables
var xOutput = createOutputVariable({onchange:function() {state.retractedX = false;}, prefix:"X"}, xFormat);
var yOutput = undefined; // Assigned in onOpen()
var zOutput = createOutputVariable({onchange:function() {state.retractedZ = false;}, prefix:"Z"}, zFormat);

var aOutput = createOutputVariable({prefix:"A"}, abcFormat);
var bOutput = createOutputVariable({prefix:"B"}, abcFormat);
var cUnwrappedOutput = createOutputVariable({prefix:"C"}, abcFormat);

// Handle wrap-around in C axis according to Biesse's rules.
function cOutput_format(c) {
    return cUnwrappedOutput.format(getWrappedC(c));
}

// Circular move center co-ordinates
// iOutput/jOutput are set to CONTROL_NONZERO in the rs274 post.
// This does not work with the Biesse controller.
var iOutput = createOutputVariable({prefix:"I", control:CONTROL_FORCE}, iFormat);
var jOutput = undefined; // Assigned in onOpen

var sOutput = createOutputVariable({prefix:"S", control:CONTROL_FORCE}, rpmFormat); // Spindle RPM
var feedOutput = createOutputVariable({prefix:"F"}, feedFormat);

var gMotionModal = createOutputVariable({onchange:function() {if (skipBlocks) {forceModals(gMotionModal);}}}, gFormat); // modal group 1 // G0-G3, ...

var gPlaneModal  = createOutputVariable({onchange:function() {if (skipBlocks) {forceModals(gPlaneModal);} forceModals(gMotionModal);}}, gFormat); // modal group 2 // G17-19

////

function defineMachine() {
    if (machineConfiguration.isReceived()) {
        warning(localize("This post is not compatible with machine configurations. All machine settings are coded in the post."));
    }

    // For this machine, the B axis rotates around X
    var bAxis = createAxis({
        coordinate: Y,
        table: false,
        axis: [1, 0, 0], 
        range: [-100, 100], // B axis range is hardcoded to -100, 100. TODO make this configurable.
        cyclic: false, // B axis does not wraparound
        tcp: true
    });

    var cAxis = createAxis({
        coordinate: Z,
        table: false,
        axis: [0, 0, 1],
        cyclic: true,
        reset: 0,
        tcp: true
    });

    // This machine has no A axis
    aOutput.disable();

    machineConfiguration = new MachineConfiguration(bAxis, cAxis);
    machineConfiguration.setVendor("Biesse");
    machineConfiguration.setModel("ISO");
    setMachineConfiguration(machineConfiguration);

    /*  Autodesk docs, p8-216 
        
        Adjust the coordinates for the rotary axes based on the TCP setting
        associated with the defined axes. This is the required setting for
        CAM defined Machine Definitions and hardcoded machine
        configurations that define the tcp variable in the createAxis
        definitions.

        ...

        If the call to calculate the rotary axes and adjust the input coordinates is not made then the tool end point
        and tool axis vector will be passed to the onRapid5D and onLinear5D multi-axis functions.
    */
    // This may not be needed, because TCP is supported on all axes by the machine
    optimizeMachineAngles2(OPTIMIZE_AXIS);
}

function activateMachine() {
}

//
// Helper functions
//

function getWorkpieceHeight() {
    return Vector.diff(getWorkpiece().upper, getWorkpiece().lower).z;
}

function isCurrentWorkplaneHorizontal() {
    return isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1));
}

// Helper functions for writing ISO 'center' sections
function writeSectionHeader(name, centerNumber) {
    centerFormat = createFormat({ minDigitsLeft: 2 });
    writeln("[" + name + centerFormat.format(centerNumber) + "]");
}

function writeSectionEnd() {
    writeln("%");
}

function writeCenterStart(centerNumber) {

    function writeParametriCode() {
        // PARAMETRI section must be repeated for each center

        var workpiece = getWorkpiece();
        // Use stock dimensions to set 'panel' dimensions for the header.
        var delta = Vector.diff(workpiece.upper, workpiece.lower);

        // HC: 'must always =1'
        // LX, LY, LZ extents of stock panel: LZ = PLPZ + PCSG
        // PLPZ: panel thickness
        // PCSG: height of pods ('jig or base board thickness') 
        // LX, LY: panel length, width
        // LZ: 'position Z of the panel upper table'

        writeBlock(
            gFormat.format(71), // NC program units = mm
            "HC=1",
            "PLPZ=" + threeDecimalFormat.format(delta.z),
            "PCSG=0", // Pod height + zOffset,
            "LX=" + threeDecimalFormat.format(delta.x),
            "LY=" + threeDecimalFormat.format(delta.y),
            "LZ=" + threeDecimalFormat.format(delta.z),
            "PUOS=0", // Origin = machine-selected
            "NFIL=" + getProperty("stopsRow"),
            "RUO=" + getProperty("panelLiftingBars"),
            "PMOA=" + getProperty("enableVacuumAllRails")
        );
    }

    writeSectionHeader("PARAMETRI", centerNumber);
    writeParametriCode();
    writeSectionEnd();

    writeSectionHeader("UTENSILI", centerNumber);
    // Should be a list of all tools used, but BSolid fills it in automatically
    writeSectionEnd();

    writeSectionHeader("CONTORNATURA", centerNumber);

    if (centerNumber == 2) {
        writeBlock("PUNI=0"); // Enable vacuum pods (PUNI=1 enables uniclamps)
        // M1 = stop program until green button pressed. 

        // Tell the machine that the code CONTOURNATURO05 applies to 'table 1' and 'table 2' machine regions.
        writeBlock("M1 WL(PRWL)=1 WL(PRWL+1)=1 WL(PRWL+2)=5");
        writeBlock("M1 WL(PRWL)=2 WL(PRWL+1)=1 WL(PRWL+2)=5");
        
        // 'Deactivation of the origin start buttons' - from BSolid post
        // Set to 0 or 1 to disable/enable each workpiece origin and its start button on the machine [?]
        writeBlock("PDS(1)=0");
        writeBlock("PDS(2)=0");
        writeBlock("PDS(3)=0");
        writeBlock("PDS(4)=0");
        
        // Enable/disable unlocking by pedal / switch when the program is finished.
        // 0 = not enabled, 1 = enabled
        writeBlock("PSBM=0");
    }
}

function writeCenterEnd(centerNumber) {
    writeSectionEnd();
    writeSectionHeader("FORATURA", centerNumber);
    writeSectionEnd();
    writeSectionHeader("TABELLEFORI", centerNumber);
    writeSectionEnd();
    writeSectionHeader("LABELC", centerNumber);
    writeSectionEnd();
    writeSectionHeader("LABELF", centerNumber);
    writeSectionEnd();
    writeSectionHeader("CONFASSIST", centerNumber);
    writeSectionEnd();
    writeSectionHeader("ATTREZZAGGIO", centerNumber);
    writeSectionEnd();

}

// Autodesk-defined support functions for callbacks

// Center number to put actual NC program code in
var ncCodeCenterNumber = 5;

function writeProgramHeader() {    
    if (unit != MM) {
        error(localize("Output units must be MM."))
    }

    warning("This post processor is licensed CC-BY-ND-NC with additions, for noncommercial use on simulator only. Do not run generated code on a CNC machine. Risk of damage to machine if this is ignored. See source code for full license details.");
    writeComment("This post processor is licensed CC-BY-ND-NC with additions, for noncommercial use on simulator only. Do not run this code on a CNC machine.");
    writeComment("Risk of damage to machine if this is ignored. See post processor source code for full license details.");

    for (i = 1; i < 5; i++) {
        writeCenterStart(i);
        writeCenterEnd(i);
    }

    writeCenterStart(ncCodeCenterNumber);
    // Callbacks for main NC program  will fill out the [CONTORNATURA05] section
}

//// Unaltered code from rs274 multi-axis.cps

/**
  Writes the specified block.
*/
function writeBlock() {
    var text = formatWords(arguments);
    if (!text) {
      return;
    }
    var prefix = getSetting("sequenceNumberPrefix", "N");
    var suffix = getSetting("writeBlockSuffix", "");
    if ((optionalSection || skipBlocks) && !getSetting("supportsOptionalBlocks", true)) {
      error(localize("Optional blocks are not supported by this post."));
    }
    if (getProperty("showSequenceNumbers") == "true") {
      if (sequenceNumber == undefined || sequenceNumber >= settings.maximumSequenceNumber) {
        sequenceNumber = getProperty("sequenceNumberStart");
      }
      if (optionalSection || skipBlocks) {
        writeWords2("/", prefix + sequenceNumber, text + suffix);
      } else {
        writeWords2(prefix + sequenceNumber, text + suffix);
      }
      sequenceNumber += getProperty("sequenceNumberIncrement");
    } else {
      if (optionalSection || skipBlocks) {
        writeWords2("/", text + suffix);
      } else {
        writeWords(text + suffix);
      }
    }
  }

/** Helper function to be able to use a default value for settings which do not exist. */
function getSetting(setting, defaultValue) {
    var result = defaultValue;
    var keys = setting.split(".");
    var obj = settings;
    for (var i in keys) {
      if (obj[keys[i]] != undefined) { // setting does exist
        result = obj[keys[i]];
        if (typeof [keys[i]] === "object") {
          obj = obj[keys[i]];
          continue;
        }
      } else { // setting does not exist, use default value
        if (defaultValue != undefined) {
          result = defaultValue;
        } else {
          error("Setting '" + keys[i] + "' has no default value and/or does not exist.");
          return undefined;
        }
      }
    }
    return result;
}

validate(settings.comments, "Setting 'comments' is required but not defined.");
function formatComment(text) {
    var prefix = settings.comments.prefix;
    var suffix = settings.comments.suffix;
    var _permittedCommentChars = settings.comments.permittedCommentChars == undefined ? "" : settings.comments.permittedCommentChars;
    switch (settings.comments.outputFormat) {
        case "upperCase":
            text = text.toUpperCase();
            _permittedCommentChars = _permittedCommentChars.toUpperCase();
            break;
        case "lowerCase":
            text = text.toLowerCase();
            _permittedCommentChars = _permittedCommentChars.toLowerCase();
            break;
        case "ignoreCase":
            _permittedCommentChars = _permittedCommentChars.toUpperCase() + _permittedCommentChars.toLowerCase();
            break;
        default:
            error(localize("Unsupported option specified for setting 'comments.outputFormat'."));
    }
    if (_permittedCommentChars != "") {
        text = filterText(String(text), _permittedCommentChars);
    }
    text = String(text).substring(0, settings.comments.maximumLineLength - prefix.length - suffix.length);
    return text != "" ? prefix + text + suffix : "";
}

/**
  Output a comment.
*/
function writeComment(text) {
    if (!text) {
        return;
    }
    var comments = String(text).split(EOL);
    for (comment in comments) {
        var _comment = formatComment(comments[comment]);
        if (_comment) {
            if (getSetting("comments.showSequenceNumbers", false)) {
                writeBlock(_comment);
            } else {
                writeln(_comment);
            }
        }
    }
}

function forceModals() {
    if (arguments.length == 0) { // reset all modal variables listed below
      if (typeof gMotionModal != "undefined") {
        gMotionModal.reset();
      }
      if (typeof gPlaneModal != "undefined") {
        gPlaneModal.reset();
      }
      if (typeof gAbsIncModal != "undefined") {
        gAbsIncModal.reset();
      }
      if (typeof gFeedModeModal != "undefined") {
        gFeedModeModal.reset();
      }
    } else {
      for (var i in arguments) {
        arguments[i].reset(); // only reset the modal variable passed to this function
      }
    }
  }

function forceFeed() {
    //currentFeedId = undefined; // Used in rs274 getFeed function, to do with parametric feeds.
    feedOutput.reset();
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
    xOutput.reset();
    yOutput.reset();
    zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
    aOutput.reset();
    bOutput.reset();
    cUnwrappedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
    forceXYZ();
    forceABC();
    forceFeed();
}

////


// Callbacks

//// From rs274 multi-axis.cps
function onComment(text) {
    writeComment(text);
}
////
  
function onOpen() {
    // Output in mm.
    // From Autodesk docs: 
    /* unit
        Contains the output units of the post processor. This is usually the
        same as the input units, either MM or IN, but can be changed in the
        onOpen function of the post processor by setting it to the desired
        units.
    */
    unit = MM;

    // 1. Define settings based on post properties

    // 2. Define the multi-axis configuration
    //// Code block from rs274 multi-axis.cps
    var receivedMachineConfiguration = machineConfiguration.isReceived();
    if (typeof defineMachine == "function") {
        defineMachine(); // hardcoded machine configuration
      }
    activateMachine(); // enable the machine optimizations and settings

    // These variables are assigned here because we need getWorkpiece() to return a valid result.
    yOffset = Math.abs(getWorkpiece().upper.y - getWorkpiece().lower.y);
    yFormat = createFormat({decimals:3, scale:-1, offset:yOffset});
    yOutput = createOutputVariable({onchange:function() {state.retractedY = false;}, prefix:"Y"}, yFormat);
    
    jFormat = createFormat({decimals:3, scale:-1, offset:yOffset}); // Flipped because Y is flipped
    jOutput = createOutputVariable({prefix:"J", control:CONTROL_FORCE}, jFormat);
    ////

    // 3. Output program name and header
    writeProgramHeader();

    // 4. Output initial startup codes.

    // 5. Perform general checks (validateCommonParameters())
}

// onPassThrough() implementation taken from Autodesk fanuc post
// This is called by executeManualNC() so that commands can be inserted at a suitable point, not just inbetween sections.
function onPassThrough(text) {
  var commands = String(text).split(",");
  for (text in commands) {
    writeBlock(commands[text]);
  }
}

// onManualNC/executeManualNC() code taken from Autodesk docs
var manualNC = [];
function onManualNC(command, value) {
  manualNC.push({command:command, value:value});
}

/**
  Processes the Manual NC commands
  Pass the desired command to process or leave argument list blank to process all buffered commands
*/
function executeManualNC(command) {
    writeComment("executeManualNC() " + manualNC);
  for (var i = 0; i < manualNC.length; ++i) {
    if (!command || (command == manualNC[i].command)) {
        writeComment("executeManualNC(): " + manualNC[i].command);
      switch(manualNC[i].command) {
     /* case COMMAND_DISPLAY_MESSAGE: // sample on explicit execution of Manual NC command
        writeComment("MSG, " + manualNC[i].value);
        break;*/
      default:
        writeComment("expanding");
        expandManualNC(manualNC[i].command, manualNC[i].value);
      }
    }
  }
  for (var i = 0; i < manualNC.length; ++i) {
    if (!command || (command == manualNC[i].command)) {
      manualNC.splice(i, 1);
    }
  }
}

function onParameter(name, value) {
    // Optional - implement manual NC commands here.
    // RS274 post uses this to write job notes to the NC file.
    // To see all parameters passed, turn on debug mode and look for onParameter() calls.
}

function getToolId(tool) {
    // Fusion requires a numeric tool Id, but Biesse can use strings.
    // Use the product ID if set, otherwise try to use the description.
    // If those fail, use the tool number.
    var toolId = tool.productId != "" ? tool.productId : tool.description;
    if (tool == "") {
        toolId = tool.number;
    }

    return toolId.toString();
}

function onSection() {
    if (isFirstSection()) {
        // Write warning message to machine/simulator console
        writeBlock("MS=\"This post processor is licensed CC-BY-ND-NC with additions.\"");
        writeBlock("MS=\"For noncommercial use on simulator only.\"");
        writeBlock("MS=\"DO NOT RUN THIS CODE ON A CNC MACHINE.\"");
        writeBlock("MS=\"Risk of damage to machine if this is ignored.\"");
        writeBlock("MS=\"See post processor source code for full license details.\"");
    }

    function spindleTiltsInCurrentSection() {
        // Returns true if the spindle tilts (or might tilt) during the current section.
        // Used to set the extractor hood position.
        return currentSection.isMultiAxis() // Spindle may tilt if the section is multi-axis 
            || !isCurrentWorkplaneHorizontal(); // 3+2 operation with tilted spindle
    }

    writeComment("Start of section " + currentSection.getId() );
    if (hasParameter("operation:operation_description")) {
        writeComment("Section name: " + getParameter("operation:operation_description"));
    }

    if (isDrillingCycle()) {
        writeDrillingSectionStart();
        return;
    }

    // 3+2 operations - set up co-ordinates
    var currentABC = currentSection.getInitialToolAxis(); //isFirstSection() ?  new Vector(0, 0, 0) : getCurrentABC();
    var abc = currentABC;
    
    if (!currentSection.isMultiAxis()) {
        // Check that the requested 3+2 orientation is supported by the machine.
        // Sets abc to the starting orientation required for the 3+2 operation.
        abc = currentSection.getABCByPreference(machineConfiguration,
            currentSection.workPlane,
            currentABC,
            ABC,
            PREFER_PREFERENCE,
            ENABLE_ALL);
        if (!isSameDirection(machineConfiguration.getDirection(abc), currentSection.workPlane.forward)) {
            error(localize("3+2 operation - orientation not supported by machine."));
        }

        // Fusion will recalculate all co-ordinates for this section to be relative to (0, 0, 0) on the specified 3+2 work plane.
        currentSection.optimize3DPositionsByMachine(machineConfiguration, currentABC, OPTIMIZE_AXIS);
    }

    // Force these values to be output on next invocation as the post processor may lose track of the spindle position
    // when using B=PRK etc.
    forceXYZ();
    forceABC();
    
    if (!isFirstSection() && !isDrillingCycle(getPreviousSection())) {
        // Raise the extractor hood before repositioning the tool.
        // Prevents clashes between hood and tool when changing between sections with different rotations in B.
        writeBlock(
            "WL(PRWL)=3 WF(PRWL+1)=1",
            mFormat.format(24)
        );

        // Wait for the extractor hood to finish moving.
        writeBlock("WL(PRWL)=1 WF(PRWL+1)=0 M24");
    }

    // Tool change, if needed, and move to initial position.
    var initialPosition = getFramePosition(currentSection.getInitialPosition()); // getFramePosition() adjusts for setRotation() and setTranslation(), if used.

    if (isToolChangeNeeded(currentSection, "number", "productId", "description")) {
        writeBlock(
            "PAN=1",
            "ST1=\"" + getToolId(tool) + "\"", 
            "ST4=\"NULL\"", // Note: Deflectors (ST4) not supported by this post.
            "L=PCUA"
        );

        writeBlock("L=GSELTP", "ST1=\"1\""); // Call machine cycle to setup for milling
        writeBlock("L=GALIAS"); // Call machine cycle to 'define the interpolating triad'

        
        writeBlock("AX=X,Y,Z,C,B", // Define axes
            "TRZ=0", // Disable TRZ correction 
            "TP=1", // Select electrospindle
            "G179", // Enable TCP
            "FX=100 FY=100 FZ=100" // Maximum feed rate
        );

        // Park the spindle in Z
        writeBlock("G1 G300 G80 Z=PRK"); 

        // Orient the spindle in B, C after arriving above the start point.
        xOutput.reset();
        yOutput.reset();
        writeBlock("G1 G300 G179 G380",
            xOutput.format(initialPosition.x),
            yOutput.format(initialPosition.y),
            bOutput.format(abc.y),
            cOutput_format(abc.z)
        );
    }
    else {        
        // Park the spindle in Z
        writeBlock("G1 G300 G80 Z=PRK FZ=100");

        // Park the spindle in B (ie. vertical)
        writeBlock("G1 G300 B=PRK FB=100");

        // Orient the spindle in B, C after arriving above the start point.
        // In some cases, BSolid simultaneously sets x, y, b, c (orient the spindle while travelling)
        // Reset X and Y so they are output again.
        // Output C again also.
        // Otherwise, G380 can move such that X, Y, C are no longer correct.
        xOutput.reset();
        yOutput.reset();
        writeBlock("G1 G300 G380 G179 TP=1",
            xOutput.format(initialPosition.x),
            yOutput.format(initialPosition.y),
            bOutput.format(abc.y),
            cOutput_format(abc.z)
        );
    }

    // Enable chip blower
    // BSolid does this before setting the extractor position
    if (getProperty("chipBlowerActivated")) {
        writeBlock("WL(PRWL)=2 WL(PRWL+1)=1 M28");
    }

    // Set extractor position
    var extractorPosition = spindleTiltsInCurrentSection() ?
        getProperty("hoodPosition5Axis")
        : getProperty("hoodPosition3Axis");

    if (extractorPosition == "offsetFromEndOfTool") {
        // Set the extractor hood position relative to the end of the tool (3-axis mode only).
        // The machine will ignore the command if B axis is currently non zero.
        // If 5 axis operations take place, this becomes meaningless - the hood does not automatically move to maintain relative height
        // If the machining operation is 3 axis but moves in Z, the hood does not move (ie. the hood does not stay a fixed height above the workpiece).
        // BSolid offers 'height relative to workpiece' and internally calculates the length to the end of the tool based on the max. depth of a machining operation.

        var hoodDistanceFromToolEnd = getProperty("hoodOffsetFromToolEnd3Axis");
        writeBlock(
            "WL(PRWL)=4 WF(PRWL+1)=" + threeDecimalFormat.format(hoodDistanceFromToolEnd),
            "WL(PRWL+3)=1", // Needed for 'automatic' mode to work, otherwise the machine ignores the hood command.
            mFormat.format(24)
        );
    }
    else if (extractorPosition == "distanceAboveWorkpiece") {
        // For 3 axis vertical spindle operations.
        // Calculate a hood position relative to the end of the tool, such that the hood will not come closer to the workpiece than 
        // 'distanceAboveWorkpiece'. 
        // Eg. if Distance Above Workpiece mode is chosen and the distance is set to 5mm, the hood will be 5mm above the workpiece
        // at the lowest Z point in the toolpath.
        var lowestZPoint = currentSection.getZRange().minimum;
        var workpieceHeight = getWorkpieceHeight();
        var offsetZ = getProperty("distanceAboveWorkpiece");

        var hoodDistancefromToolEnd = workpieceHeight - lowestZPoint + offsetZ;

        writeBlock(
            "WL(PRWL)=4 WF(PRWL+1)=" + threeDecimalFormat.format(hoodDistancefromToolEnd),
            "WL(PRWL+3)=1", // Needed for 'automatic' mode to work, otherwise the machine ignores the hood command.
            mFormat.format(24)
        );
    }
    else {
        // Set the extractor hood position to a fixed setting between 1-12
        writeBlock(
            "WL(PRWL)=3 WF(PRWL+1)=" + extractorPosition,
            mFormat.format(24)
        );
    }

    writeBlock("XO=" + threeDecimalFormat.format(getProperty("xOffset")),
        "YO=" + threeDecimalFormat.format(0 - getProperty("yOffset")),
        "ZO=" + threeDecimalFormat.format(0 - getProperty("zOffset"))
        );

    // Output any manual NC commands added by the user. This is done here so that axes are defined, the spindle is selected, etc
    // ie. the machine is in a valid state. Otherwise commands like setting ZO (Z offset) may fail.
    executeManualNC();

    // Start the spindle
    writeBlock(
        mFormat.format(tool.clockwise ? 3 : 4), // Start spindle
        sOutput.format(spindleSpeed)
    );

    writeBlock("L=PTRZ");
    writeBlock(mFormat.format(41));
}

function onSectionEnd() {
    if (isDrillingCycle()) {
        writeDrillingSectionEnd();
        return;
    }

    // Park in Z
    writeBlock("G1 G300 G80 Z=PRK");

    // Turn off the spindle, raise the extractor and park if the next section needs a tool change or is drilling.
    if (!isLastSection() && isToolChangeNeeded(getNextSection())) {
        // Extractor hood up
        writeBlock("WL(PRWL)=3 WF(PRWL+1)=1 M24");
        
        // Deactivate chip blower
        if (getProperty("chipBlowerActivated")) {
            writeBlock("WL(PRWL)=2 WL(PRWL+1)=0 M28");
        }

        // Stop spindle
        writeBlock(mFormat.format(5));

        // Park in B (needed prior to tool change)
        writeBlock("G1 G300 B=PRK");
        
        // Wait for extractor hood to finish moving
        writeBlock("WL(PRWL)=1 WF(PRWL+1)=0 M24");

        if (isDrillingCycle(getNextSection())) {
            // TPO = Disabling the active corrector, resetting selected TP, 
            // resetting the TP axes gantry and parking of any master Z axis of the selected TP setting axes.
            // TRZ=0 Disable TRZ correction
            writeBlock("TP0", "TRZ=0");
        }
    }
}


function onDwell(seconds) {
    error(localize("Callback not implemented."));
}

function onSpindleSpeed(spindleSpeed) {
    writeBlock(sOutput.format(spindleSpeed));
}

function onOrientateSpindle(angle) {
    error(localize("Callback not implemented."));
}

function onCycle() {
    writeComment("onCycle()");
    if (!isDrillingCycle() || cycleType != "drilling") {
        cycleNotSupported();
    }

    if (!isCurrentWorkplaneHorizontal()) {
        error(localize("Only vertical drilling is supported."));
    }
}

function onCyclePoint(x, y, z) {    
    // Calculate safe retract height for drill block.
    // TODO set this as a variable in the post or read it from the PLC
    warning("Drill retract height hardcoded to stock height + 50mm");
    var workpiece = getWorkpiece();
    var delta = Vector.diff(workpiece.upper, workpiece.lower);
    var drillRetractOffset = 50; 
    var retractHeight = delta.z + drillRetractOffset;

    if (isFirstCyclePoint()) {
        // Rapid move to clearance height
        writeBlock(gFormat.format(1),
            gFormat.format(300),
            zOutput.format(retractHeight),
            "T=" + intOutput.format(tool.number)
        );
    }

    // Rapid move to X, Y point above hole
    writeBlock(gFormat.format(0),
        xOutput.format(x),
        yOutput.format(y)
    );

    // Move down to entry of drill into piece
    writeBlock(gFormat.format(0),
        zOutput.format(cycle.stock),
        "FZ=" + feedFormat.format(cycle.feedrate) // Fusion sends mm/min, Biesse wants m/min
    );

    // Drill to bottom
    writeBlock(gFormat.format(0),
        zOutput.format(z)
    );

    // Fast retract to surface
    writeBlock(gFormat.format(0),
        zOutput.format(cycle.stock),
        "FZ=" + feedFormat.format(cycle.retractFeedrate)
    );

    // Fast retract to clearance height (for moving between holes in the same cycle)
    writeBlock(gFormat.format(0),
        zOutput.format(retractHeight)
    );
}

function writeDrillingSectionStart() {
    // Tools must be chosen by spindle number - (use tool.number)
    
    // Position the 5 axis head out of the way, safe for drilling.
    // As documented in AU04919N p13.
    // It also says to use L=GRESETAX afterwards.
    // TODO test this, but it is not present in the cicli/ folder
    writeBlock("PAN=1 L=GRIP5AX");

    // Select the vertical drill and initialize it
    writeBlock("ST1=\"" + tool.number + "\"");
    writeBlock("L=GSELT");
    writeBlock("L=GALIAS");

    writeBlock(
            "XO=" + threeDecimalFormat.format(getProperty("xOffset")),
            "YO=" + threeDecimalFormat.format(0 - getProperty("yOffset")),
            "ZO=" + threeDecimalFormat.format(0 - getProperty("zOffset"))
    );

    // Output any manual NC commands added by the user. This is done here so that axes are defined, the spindle is selected, etc
    // ie. the machine is in a valid state. Otherwise commands like setting ZO (Z offset) may fail.
    executeManualNC();
    
    // Start the drill spindle
    writeBlock(mFormat.format(3),
        sOutput.format(spindleSpeed)
    );

    // M23 ; Request or await pnneumatic axis (eg. drill block Z axis may be pneumatic)
    // WL(PWRL)=3 - request movement of pneumatic axis 
    // WF(PRWL+1)=2 - The position of the pneumatic axis (1 is the highest position, increasing numbers are lower positions)
    writeBlock("WL(PRWL)=3 WF(PRWL+1)=2 M23");

    // M29 Request enabling of spindle and suction hood 
    // WL(PRWL+1)=1 moves selected spindles to the working position, retracts any unused spindles that may be extended.
    // And enables the extractor hood for vertical drills.
    writeBlock("M29 WL(PRWL+1)=1");

    // Enable TRZ (vertical axis compensation)
    writeBlock("L=PTRZ");

    // M41 Wait for all components to finish moving into position
    // Because pneumatic drill block slide and dust hood may have been moved 
    writeBlock(mFormat.format(41));
}

function onCycleEnd() {
}

function writeDrillingSectionEnd() {
    // M29 Send request to spindle
    // WL(PRWL+1)= 0 Move all drill spindles to parked position
    writeBlock("M29 WL(PRWL+1)=0");

    // Request pneumatic axis to position 1 (highest position)
    writeBlock("WL(PRWL)=3 WF(PRWL+1)=1 M23");

    writeBlock(mFormat.format(5), // Spindle off
        gFormat.format(0),
        "Z=PRK"); // Park spindle 

    // M23 Spindle request
    // WL(PRWL)=1 Wait for pneumatic axis to finish moving
    writeBlock("WL(PRWL)=1 M23");

    // T0 ; Shut down vertical drill spindle
    writeBlock("T0");

    // Park the spindle, in case it is used the next section
    if (!isLastSection() && !isDrillingCycle(getNextSection())) {
        writeComment("End of drilling cycle - parking spindle for next milling operation.");

        writeBlock("ST1=\"1\" L=GSELTP");
        writeBlock("L=GALIAS");
        writeBlock("G1 G300 Z=PRK");
        writeBlock("G1 G300 B=PRK");
    }
}

function onRewindMachineEntry(_a, _b, _c) {
    error(localize("Callback not implemented."));
}

function onMoveToSafeRetractPosition() {
    error(localize("Callback not implemented."));
}

function onRotateAxes(_x, _y, _z, _a, _b, _c) {
    error(localize("Callback not implemented."));
}

function onReturnFromSafeRetractPosition(_x, _y, _z) {
    error(localize("Callback not implemented."));
}

function onClose() {
    // Machine shutdown sequence according to BSuite post processor output.
    if (!isDrillingCycle()) {
        // Extractor hood up
        writeBlock("WL(PRWL)=3 WF(PRWL+1)=1 M24");

        // Turn off dynamic TCP if there were multi-axis programs running.
        writeBlock(gFormat.format(80));
    }
    
    writeBlock("L=GSELTP ST1=\"1\"");
    writeBlock("L=GALIAS");

    // Move Z to parking position 
    writeBlock(
        gFormat.format(1),
        gFormat.format(300),
        "Z=PRK FX=100 FY=100 FZ=100",
        mFormat.format(5) // Spindle off
    );
    
    // Park B and C axes
    writeBlock(
        gFormat.format(1),
        gFormat.format(300),
        "C=PRK B=PRK FB=13"
    );

    // Wait for extractor to finish moving
    writeBlock("WL(PRWL)=1 WF(PRWL+1)=0 M24");

    writeBlock("TP0", "TRZ=0");

    writeBlock("AX=X,Y,Z");
    
    writeCenterEnd(ncCodeCenterNumber);

    writeSectionEnd();
}

function onRadiusCompensation() {

    /* From Autodesk post docs:

        The onRadiusCompensation function is called when the radius (cutter) compensation mode changes. It
        will typically set the pending compensation mode, which will be handled in the motion functions
        (onRapid, onLinear, onCircular, etc.). Radius compensation, when enabled in an operation, will be
        enabled on the move approaching the part and disabled after moving off the part.
        The supportsRadiusCompensation setting determines if radius compensation is supported by the
        machine control.
        The state of radius compensation is stored in the global radiusCompensation variable and is not passed
        to the onRadiusCompensation function. Radius compensation is defined when creating the machining
        operation in Fusion (1).

    */
    // pendingRadiusCompensation = radiusCompensation;
    error(localize("Radius compensation not supported - use 'In Machine' radius compensation."));
}

// Derived from rs274 post and modified per biesse iso post to output G1 G300 for rapid moves
// (Maintains tool radius correction and dynamic tcp state, compared to using G0)
// FX, FY, FZ added - TODO - see if they are valid/necessary
function onRapid(_x, _y, _z) {
    if (isDrillingCycle()) {
        // Do not output the move if this is a drilling operation.
        // Fusion generates a rapid move that is not needed, because it loses
        // track of where the spindle is (due to use of Z=PRK).
        // Spindle position is totally controlled by onCycle...() commands.
       return;
    }

    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);

    if (x || y || z) {
        if (pendingRadiusCompensation >= 0) {
            error(localize("Radius compensation mode cannot be changed at rapid traversal."));
            return;
        }
        writeComment("Rapid move");
        // Force output of 'G1 G300' on the same line.
        gMotionModal.reset();

        // TODO - find out whether FX, FY, FZ are needed.

        writeBlock(
            gMotionModal.format(1),
            gFormat.format(300),
            x, y, z,
            "FX=100", 
            "FY=100",
            "FZ=100"
        );

        gMotionModal.reset();
        xOutput.reset();
        yOutput.reset();
        zOutput.reset();

        feedOutput.reset(); 
    }
}

function getFeed(f) {
    return feedOutput.format(f);
}

// Derived from RS274 post
function onLinear(_x, _y, _z, feed) {
    if (pendingRadiusCompensation >= 0) {
        xOutput.reset();
        yOutput.reset();
    }
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    if (x || y || z) {
        if (pendingRadiusCompensation >= 0) {
            pendingRadiusCompensation = -1;
            var d = getSetting("outputToolDiameterOffset", true) ? diameterOffsetFormat.format(tool.diameterOffset) : "";
            writeBlock(gPlaneModal.format(17));
            switch (radiusCompensation) {
                case RADIUS_COMPENSATION_LEFT:
                    writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, z, d, getFeed(feed));
                    break;
                case RADIUS_COMPENSATION_RIGHT:
                    writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, z, d, getFeed(feed));
                    break;
                default:
                    writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, getFeed(feed));
            }
        } else {
            writeBlock(gMotionModal.format(1), x, y, z, getFeed(feed));
        }
    }
}

// Derived from rs274 post, with tool vector format output removed and converted to g1/g300.
function onRapid5D(_x, _y, _z, _a, _b, _c) {
    if (pendingRadiusCompensation >= 0) {
        error(localize("Radius compensation mode cannot be changed at rapid traversal."));
        return;
    }

    // TODO - determine whether this is necessary
    if (!currentSection.isOptimizedForMachine()) {
        forceXYZ();
    }

    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a = aOutput.format(_a);
    var b = bOutput.format(_b);
    var c = cOutput_format(_c);

    if (x || y || z || a || b || c) {
        gMotionModal.reset(); // Force output of G1 G300 on the same line
        writeBlock(
            gMotionModal.format(1), 
            gMotionModal.format(300),
            x, y, z, 
            a, b, c);
        forceFeed();
    }
}

var previousC = 0;
var outC = 0;

function getWrappedC(c) {
    // Handle 'passage through zero' rules
    // Call this when handling NC code.
    // For this controller, when passing through 360 degrees (eg. 359 -> 1 -> 2).
    // output one value in excess of 360 (in this case 361) so the spindle takes the shortest path.
    // When passing through zero (eg. 1 -> -1 -> -2), 
    // output one value below zero, then wrap it (it becomes 1 -> -1 -> 358).
    // Fusion may output indefinitely increasing or decreasing C values (eg. C=20000).
    // This function constrains C values within 0->360 with the exceptions above.

    // call getResultingValue() because the value might get rounded to 0.0
    // and not treated as a passage through zero by the machine.
    // This causes an almost 360-degree c-axis spin in the wrong direction.
    if (cUnwrappedOutput.getResultingValue(outC) != 0.0) {
        if (outC > (Math.PI * 2)) {
            writeComment("Clipping c: " + c + "->" + outC);
            outC %= (Math.PI * 2);
        }
        else if (outC < 0) {
            writeComment("Clipping c: " + c + "->" + outC);
            outC = (Math.PI * 2) + outC;
        }
    }

    // Clip >360 degree rotations to 360 degrees. (For longer rotations, a helix should be used)
    var deltaC = (c - previousC) % (Math.PI * 2);
    outC += deltaC;
    previousC = c;

    return outC;
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed, feedMode) {
    if (pendingRadiusCompensation >= 0) {
        error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    }

    if (!currentSection.isOptimizedForMachine()) {
        forceXYZ();
    }

    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a = aOutput.format(_a);
    var b = bOutput.format(_b);
    var c = cOutput_format(_c);
    
    if (x || y || z || a || b || c) {
        writeBlock(gMotionModal.format(1), x, y, z, a, b, c, getFeed(feed));
    }
}

// Derived from rs274 post
function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
    if (getCircularPlane() != PLANE_XY) {
        // Circular moves are only allowed on the XY plane, so linearize all other circular moves.
        linearize(tolerance);
    }
    else if (isHelical() || isFullCircle()) {
        linearize(tolerance);
    }
    else { 
        writeComment("onCircular, plane = " + getCircularPlane() + ", PLANE_XY=" + PLANE_XY);

        writeBlock(
            gMotionModal.format(!clockwise ? 2 : 3), // Note: CW and CCW are flipped due to flipped co-ordinates
            xOutput.format(x),
            yOutput.format(y),
            zOutput.format(z),
            iOutput.format(cx),
            jOutput.format(cy),
            feedOutput.format(feed)
        );
    }
}
