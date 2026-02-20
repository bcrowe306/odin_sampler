package main 

import "core:math"
import "core:fmt"



modbuf :: proc(buf: []f32) {
    for i in 0 ..< len(buf) {
        buf[i] = math.sin_f32(2.0 * math.PI * 440.0 * f32(i) / 44100.0)
    }
}





main :: proc() {
    buf := make([]f32, 5)
    fmt.println("Buffer before: ", buf)
    modbuf(buf)
    fmt.println("Buffer after: ", buf)

}