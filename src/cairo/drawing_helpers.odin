package cairo

import "core:c"
import "core:fmt"
import "core:math"


set_color :: proc(cr: ^context_t, color: Color) {
    set_source_rgba(cr, color.r, color.g, color.b, color.a)
}

draw_top_rounded_rectangle :: proc(cr: ^context_t, x, y, width, height, radius: f64, fill_rect: bool, color: Color) {
    degrees := math.PI / 180.0;
    new_sub_path (cr);
    arc (cr, x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
    // arc (cr, x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
    line_to(cr, x + width, y + height)
    line_to(cr, x, y + height)
    // arc (cr, x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
    arc (cr, x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
    close_path (cr);

    set_color(cr, color)
    if fill_rect {
        fill_preserve (cr);
    }
    else {
        set_line_width (cr, 2.0);
        stroke (cr);
    }
    
}


draw_text :: proc(cr: ^context_t, text: string, x, y, font_size: f64, color : Color) {
    select_font_face(cr, "Sans", font_slant_t.NORMAL, font_weight_t.NORMAL)
    set_font_size(cr, font_size)
    set_source_rgba(cr, color.r, color.g, color.b, color.a)
    text_cstring: cstring = fmt.ctprint(text)
    exts: text_extents_t
    text_extents(cr, text_cstring, &exts)
    move_to(cr, x, exts.height + y)
    show_text(cr, fmt.ctprint(text))
}

draw_text_centered :: proc(cr: ^context_t, text: string, bounds: rectangle_t, font_size: f64, color : Color) {
    // draw text centered within the bounds
    select_font_face(cr, "Sans", font_slant_t.NORMAL, font_weight_t.NORMAL)
    set_font_size(cr, font_size)
    set_source_rgba(cr, color.r, color.g, color.b, color.a)
    text_cstring: cstring = fmt.ctprint(text)
    exts: text_extents_t
    text_extents(cr, text_cstring, &exts)
    x := bounds.x + (bounds.width - exts.width) / 2
    y := bounds.y + (bounds.height - exts.height) / 2
    move_to(cr, x, y + exts.height)
    show_text(cr, fmt.ctprint(text))
}

