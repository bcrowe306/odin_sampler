package main 

import "src/app"
import "core:fmt"
import "core:thread"


main :: proc() {
    using app
    using fmt
    first_name := "Brandon"
    new_timer := createTimer(1.0/ 2.0, true, false, proc(user_data: ^TimerUserData) {
        first_name := cast(^string)user_data.user_data
        fmt.printfln("Timer ticked! Frame count: %d, User data: %s", user_data.timer.frame_count, first_name^)
    }, &first_name)
    new_timer->start()
    thread.join(new_timer.thread)
}