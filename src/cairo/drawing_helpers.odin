package cairo

import "core:c"
import "core:fmt"
import "core:math"
import clay  "../../lib/clay-odin"


Color :: [4]f64
WHITE : Color = {1.0, 1.0, 1.0, 1.0}
BLACK : Color = {0.0, 0.0, 0.0, 1.0}
RED : Color = {1.0, 0.0, 0.0, 1.0}
GREEN : Color = {0.0, 1.0, 0.0, 1.0}
BLUE : Color = {0.0, 0.0, 1.0, 1.0}
FONT_FAMILY: cstring = "serif"



// display render function signature
displayRenderFunc :: proc(surface: ^surface_t, xPos, yPos, width, height: i32, data: rawptr)

SetupAntialiasing :: proc(cr: ^context_t) {
    set_antialias(cr, antialias_t.NONE)
    font_options := font_options_create()
    font_options_set_antialias(font_options, antialias_t.NONE)
    set_font_options(cr, font_options)
    font_options_destroy(font_options)
}


SetupSurface :: proc(format: format_t, width, height: i32) -> (^surface_t, ^context_t) {
    surface := image_surface_create(format, width, height)
    cr := create(surface)
    SetupAntialiasing(cr)
    return surface, cr
}


set_color :: proc(cr: ^context_t, color: Color) {
    set_source_rgba(cr, color.r, color.g, color.b, color.a)
}

draw_top_rounded_rectangle :: proc(cr: ^context_t, x, y, width, height, radius: f64, fill_rect: bool, color: Color) {
    degrees := math.PI / 180.0;
    new_sub_path (cr);
    set_color(cr, color)
    arc (cr, x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
    // arc (cr, x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
    line_to(cr, x + width, y + height)
    line_to(cr, x, y + height)
    // arc (cr, x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
    arc (cr, x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
    close_path (cr);

    
    if fill_rect {
        fill(cr);
    }
    else {
        set_line_width (cr, 1.0);
        stroke (cr);
    }
    
}


draw_text :: proc(cr: ^context_t, text: string, x, y, font_size: f64, color : Color) {
    select_font_face(cr, FONT_FAMILY, font_slant_t.NORMAL, font_weight_t.NORMAL)
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
    select_font_face(cr, FONT_FAMILY, font_slant_t.NORMAL, font_weight_t.NORMAL)
    set_font_size(cr, font_size)
    set_source_rgba(cr, color.r, color.g, color.b, color.a)
    text_cstring: cstring = fmt.ctprint(text)
    exts: text_extents_t
    text_extents(cr, text_cstring, &exts)
    // Print exts
    x := bounds.x + (bounds.width - exts.width) / 2
    y := bounds.y + (bounds.height - exts.height) / 2
    move_to(cr, x, y + exts.height - (exts.y_bearing + exts.height))
    show_text(cr, text_cstring)
}


draw_rectangle :: proc(cr: ^context_t, x, y, width, height: f64, fill_rect: bool, color: Color, thickness: f64 = 1.0) {
    move_to(cr, x, y)
    rectangle(cr, x, y, width, height)
    set_color(cr, color)
    if fill_rect {
        fill(cr)
    }
    else {
        set_line_width(cr, thickness)
        stroke(cr)
    }
}

draw_rectangle_bounds :: proc(cr: ^context_t, bounds: rectangle_t, fill_rect: bool, color: Color, thickness: f64 = 1.0) {
    move_to(cr, bounds.x, bounds.y)
    rectangle(cr, bounds.x, bounds.y, bounds.width, bounds.height)
    set_color(cr, color)
    if fill_rect {
        fill(cr)
    }
    else {
        set_line_width(cr, thickness)
        stroke(cr)
    }
}

draw_clay_rectangle :: proc(cr: ^context_t, command: ^clay.RenderCommand) {
    if command.commandType == clay.RenderCommandType.Rectangle {
        
        draw_rectangle(cr, f64(command.boundingBox.x), f64(command.boundingBox.y), f64(command.boundingBox.width), f64(command.boundingBox.height), true, colorFromClayColor(command.renderData.rectangle.backgroundColor))
    }
}

colorFromClayColor :: proc(clayColor: clay.Color) -> Color {
    return Color{
        f64(clayColor.r) / 255.0,
        f64(clayColor.g) / 255.0,
        f64(clayColor.b) / 255.0,
        f64(clayColor.a) / 255.0,
    }
}

getRectFromClayCmd :: proc(command: ^clay.RenderCommand) -> rectangle_t {
    return rectangle_t{
        f64(command.boundingBox.x),
        f64(command.boundingBox.y),
        f64(command.boundingBox.width),
        f64(command.boundingBox.height),
    }
}


draw_line :: proc(cr: ^context_t, x1, y1, x2, y2, line_width: f64, color: Color) {
    set_line_width(cr, line_width)
    set_color(cr, color)
    move_to(cr, x1, y1)
    line_to(cr, x2, y2)
    stroke(cr)
}

draw_horizontal_line :: proc(cr: ^context_t, y, x1, x2, line_width: f64, color: Color) {
    draw_line(cr, x1, y, x2, y, line_width, color)
}

draw_vertical_line :: proc(cr: ^context_t, x, y1, y2, line_width: f64, color: Color) {
    draw_line(cr, x, y1, x, y2, line_width, color)
}
