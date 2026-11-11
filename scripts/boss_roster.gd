extends RefCounted
## Floor identity includes a silhouette, readable name and a distinct attack rotation.
const NAMES := ["The Headsman","Jade Oracle","Sanctuary Hound","Bell Wraith","Cathedral Titan","Thorn Hierophant","Jade Scorpion","Mirror Queen","Cinder Stag","Fallen Regent"]
const SEQUENCES := [
	["spread","charge"], ["ring","ground","spread"],
	["charge","hunt","charge"], ["ring","cross","ground"],
	["eruption","charge","ground"], ["spiral","spread","ground"],
	["hunt","cross","charge"], ["cross","ring","spread"],
	["charge","eruption","spiral"], ["combo","ring","hunt","spiral"]
]
static func name_for(floor_number: int) -> String: return NAMES[clampi(floor_number-1,0,9)]
static func sequence(floor_number: int) -> Array: return SEQUENCES[clampi(floor_number-1,0,9)]
