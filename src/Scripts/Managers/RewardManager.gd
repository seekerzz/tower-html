extends Node

# Dictionary to store artifacts. Key: artifact_id, Value: data or true
var artifacts: Dictionary = {}

func has_artifact(artifact_id: String) -> bool:
	return artifacts.has(artifact_id)

func add_artifact(artifact_id: String):
	artifacts[artifact_id] = true
