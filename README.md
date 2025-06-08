# OversizeRender MAXScript for 3ds Max

## Overview

OversizeRender is a MAXScript tool for 3ds Max designed to help users easily set up and manage "oversize" or "over-scan" rendering. This technique involves rendering an image larger than the final intended dimensions, providing extra pixels around the edges. This is commonly used for:

*   **Post-production stabilization:** Extra image area allows for camera shake to be smoothed out without losing frame edges.
*   **Lens distortion correction:** Provides the necessary data to undistort an image without black edges.
*   **Reframing/Composition adjustments:** Offers flexibility in post-production to slightly alter the composition.
*   **Motion blur or depth of field:** Ensures effects that extend beyond the frame border are rendered correctly.

The script provides a user-friendly interface to define a base resolution and then calculate and apply an oversized resolution using various methods. It can modify the current scene's render settings and camera, or create new, non-destructive cameras with baked animation.

## Features

*   **Source Camera Selection:** Pick any camera in your scene as the basis for operations.
*   **Base Resolution & FOV/FL:** Define the intended final resolution and the camera's Field of View (FOV) or Focal Length (FL).
    *   Supports both standard cameras (FOV) and VRayPhysicalCameras (Focal Length).
    *   Option to quickly grab current render settings and camera FOV/FL.
*   **Multiple Oversize Methods:**
    1.  **Uniform Pixels:** Adds a specified number of pixels equally to all sides.
    2.  **Percentage:** Increases resolution by a percentage of the base resolution.
    3.  **Separate Pixels:** Adds a specified number of pixels independently to X and Y axes.
    4.  **Final Resolution:** Directly specify the desired final oversized resolution.
*   **FOV/FL Compensation:** Automatically adjusts the camera's FOV/FL when applying an oversized resolution to maintain the original framing within the new, larger render area.
*   **Pixel Aspect Ratio:** Option to take the render pixel aspect ratio into account for height calculations.
*   **Camera Creation & Animation Baking:**
    *   Option to create new "base" and "oversized" cameras instead of modifying the selected one.
    *   If creating new cameras, animation from the source camera can be baked onto them with linear interpolation.
*   **Apply Settings:**
    *   Apply "Base" settings to the current render setup and selected camera.
    *   Apply "Oversized" settings to the current render setup and selected camera.
*   **Save/Load Settings:**
    *   Settings (base resolution, oversize method, values) can be saved into the User Properties of a camera object.
    *   These settings can be loaded back into the script from a camera.
*   **Persistent UI Settings:** Most UI values are remembered between 3ds Max sessions.

## How to Use

1.  Run the script (e.g., via Scripting > Run Script or by dragging it into a viewport).
2.  **Pick Source Camera:**
    *   Click `Pick Source Camera` and select the camera you want to work with.
    *   The camera's name will appear below the button.
    *   Click `Refresh` to update the FOV/FL display from the currently selected camera if you've changed it manually.
3.  **Define Base Resolution:**
    *   In the "Base Resolution" group, set the `ResX`, `ResY`, and `FOV` (or `FL` if a VRayPhysicalCamera is selected) that represent your intended *final* cropped output.
    *   Alternatively, click `use Current` to populate these fields from the current render settings and the selected camera's FOV/FL.
4.  **Options:**
    *   `bake new cameras`: Check this if you want the "Create Cameras" button to generate new cameras with baked animation. Uncheck to have it create new cameras that inherit the source camera's animation (if any) directly.
    *   `use pixelaspect`: Check this if your render pixel aspect ratio is not 1.0 and you want the oversize height calculation to respect it.
5.  **Choose Oversize Method:**
    *   In the "Oversize Method" group, select one of the radio buttons:
        *   **Uniform Pixels:** Enter the number of extra pixels to add to each side (horizontally and vertically).
        *   **Percentage:** Enter the percentage by which to increase the resolution.
        *   **Separate Pixels:** Enter the extra pixels to add to X and Y axes independently.
        *   **Final Resolution:** Directly input the target `Final X` and `Final Y` resolution for the oversized render.
    *   The relevant input fields will appear below the radio buttons.
6.  **Actions:**
    *   `use Base`: Applies the "Base Resolution" and FOV/FL to the current scene's render settings and modifies the *selected source camera*.
    *   `use Oversized`: Calculates the oversized resolution and the compensated FOV/FL, then applies them to the current scene's render settings and modifies the *selected source camera*.
    *   `Create Cameras`:
        *   Creates two new cameras: `[SourceCameraName]_base` and `[SourceCameraName]_oversize`.
        *   The `_base` camera will have the base FOV/FL.
        *   The `_oversize` camera will have the compensated FOV/FL for the oversized resolution.
        *   If `bake new cameras` is checked, animation from the source camera will be baked onto these new cameras.
        *   Saves the current script settings into the User Properties of both newly created cameras.
    *   `Load from Cam`: If the currently picked source camera has OversizeRender data saved in its User Properties (e.g., from a previous "Create Cameras" operation), this button will load those settings back into the script's UI.

## UI Breakdown

*   **Main Window (`OversizeRender`)**
    *   `try ( destroyDialog rOverSizeRender ) catch()`: Ensures only one instance of the dialog is open.
*   **Persistent Global Variables:**
    *   `rOversizeRender_BaseX`, `_BaseY`, `_BaseFov`, `_BaseFl`: Store base resolution and FOV/FL.
    *   `rOversizeRender_UsePixAspect`, `_BakeNewCameras`: Store checkbox states.
    *   `rOversizeRender_oversizeMode`: Stores the selected oversize method.
    *   `rOversizeRender_oversize`, `_oversizePercent`, `_oversizeX`, `_oversizeY`, `_finalResX`, `_finalResY`: Store values for the different oversize methods.
    *   `rOversizeRender_selectedCamera`: Stores the last picked camera.
*   **Group: `Source Camera`**
    *   `btnPickCamera`: Pickbutton to select the camera to operate on.
    *   `btnRefreshCam`: Button to update FOV/FL info from the selected camera.
    *   `lblSelectedCam`: Label displaying the name of the picked camera.
*   **Group: `Base Resolution`**
    *   `spnBaseX`, `spnBaseY`: Spinners for base render width and height.
    *   `spnBaseFov`: Spinner for base FOV (or Focal Length for VRayPhysicalCameras - label changes).
    *   `btnUseCurrent`: Button to set base values from current scene/camera settings.
*   **Checkboxes:**
    *   `chkBakeNewCameras`: Toggles baking animation when creating new cameras.
    *   `chkUsePixAspect`: Toggles using pixel aspect ratio in calculations.
*   **Group: `Oversize Method`**
    *   `rdoOversizeMode`: Radio buttons to select the method: "Uniform Pixels", "Percentage", "Separate Pixels", "Final Resolution".
    *   Dynamically shown spinners/labels based on `rdoOversizeMode` selection:
        *   `spnOverSize`: For "Uniform Pixels".
        *   `spnOversizePercent`: For "Percentage".
        *   `lblSepX`, `spnOversizeX`, `lblSepY`, `spnOversizeY`: For "Separate Pixels".
        *   `lblFinalX`, `spnFinalResX`, `lblFinalY`, `spnFinalResY`: For "Final Resolution".
*   **Group: `Actions`**
    *   `btnUseBase`: Applies base settings to current scene/camera.
    *   `btnUseOversized`: Applies oversized settings to current scene/camera (with FOV compensation).
    *   `btnCreateCameras`: Creates new base and oversized cameras, optionally with baked animation, and saves settings to them.
    *   `btnLoadFromCam`: Loads settings from the selected camera's User Properties.

## Notes

*   When using `btnUseOversized` or creating an `_oversize` camera, the script calculates a new FOV (or Focal Length) to ensure that the content framed by the original "Base Resolution" and "Base FOV/FL" remains the same within the larger, oversized render.
*   The script specifically checks for `VRayPhysicalCamera` type to handle Focal Length correctly; otherwise, it assumes standard camera FOV.
*   For VRayPhysicalCameras, the script will warn if the camera's `film_width` does not match the scene's `getRendApertureWidth()` when calculating FOV compensation, as this mismatch can lead to incorrect results.
*   Animation baking uses a temporary dummy object and constraints, then transfers keys with linear interpolation to the new camera(s).

This script is a valuable utility for workflows requiring flexible render dimensions and post-production adjustments.
