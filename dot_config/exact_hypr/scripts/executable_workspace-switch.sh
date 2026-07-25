#!/bin/bash

operation=$1
workspace=$2

monitor_id=$(hyprctl activeworkspace | grep "monitorID" | awk '{print $2}')
workspace_id=$(($monitor_id * 10 + $workspace))
echo "Final Operation: $operation to $workspace_id"

if [[ $operation == "switch" ]]; then
	hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = '$workspace_id', monitor = '$monitor_id' }))";
	hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$workspace_id' }))";
fi

if [[ $operation == "movesilent" ]]; then
	hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = '$workspace_id', monitor = '$monitor_id' }))";
	hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = '$workspace_id', follow = false }))";
fi

if [[ $operation == "move" ]]; then
	hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ workspace = '$workspace_id', monitor = '$monitor_id' }))";
	hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = '$workspace_id' }))";
fi
