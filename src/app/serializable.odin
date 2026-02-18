package app


Serializable :: struct {
    serialize: proc(object: rawptr) -> string,
    deserialize: proc(serialized: string) -> rawptr,
}