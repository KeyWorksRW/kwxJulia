# High-level Sizer wrappers for layout management

# Custom REPL display for all sizer types
function Base.show(io::IO, ::MIME"text/plain", sizer::WxSizer)
    print(io, "$(typeof(sizer))(ptr=$(sizer.ptr))")
end

# =============================================================================
# WxBoxSizer
# =============================================================================

"""
    WxBoxSizer

A sizer that lays out its children in a single row or column.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxBoxSizer C++ object
"""
mutable struct WxBoxSizer <: WxSizer
    ptr::Ptr{Cvoid}
end

"""
    WxBoxSizer(orientation::Symbol) -> WxBoxSizer
    WxBoxSizer(orientation::Integer) -> WxBoxSizer

Create a new box sizer with the given orientation.

# Arguments
- `orientation` - Either `:horizontal`/`:vertical` (Symbol) or `wxHORIZONTAL[]`/`wxVERTICAL[]` (Integer)

# Example
```julia
sizer = WxBoxSizer(:vertical)
add!(sizer, button, proportion=0, flags=wxALL[] | wxEXPAND[], border=5)
set_sizer(frame, sizer)
```
"""
function WxBoxSizer(orientation::Symbol)
    orient = if orientation == :horizontal
        wxHORIZONTAL[]
    elseif orientation == :vertical
        wxVERTICAL[]
    else
        error("Invalid orientation: $orientation (expected :horizontal or :vertical)")
    end
    ptr = wxboxsizer_create(orient)
    if ptr == C_NULL
        error("Failed to create WxBoxSizer")
    end
    WxBoxSizer(ptr)
end

function WxBoxSizer(orientation::Integer)
    ptr = wxboxsizer_create(Int(orientation))
    if ptr == C_NULL
        error("Failed to create WxBoxSizer")
    end
    WxBoxSizer(ptr)
end

"""
    get_orientation(sizer::WxBoxSizer) -> Int

Get the sizer orientation (wxHORIZONTAL or wxVERTICAL).
"""
function get_orientation(sizer::WxBoxSizer)
    wxboxsizer_getorientation(sizer.ptr)
end

# =============================================================================
# WxGridSizer
# =============================================================================

"""
    WxGridSizer

A sizer that lays out its children in a regular grid where all cells have the same size.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxGridSizer C++ object
"""
mutable struct WxGridSizer <: WxSizer
    ptr::Ptr{Cvoid}
end

"""
    WxGridSizer(rows::Int, cols::Int; vgap::Int=0, hgap::Int=0) -> WxGridSizer

Create a new grid sizer.

# Arguments
- `rows::Int` - Number of rows (0 means determined by number of items and cols)
- `cols::Int` - Number of columns (0 means determined by number of items and rows)

# Keyword Arguments
- `vgap::Int = 0` - Vertical gap between rows in pixels
- `hgap::Int = 0` - Horizontal gap between columns in pixels

# Example
```julia
sizer = WxGridSizer(2, 3, vgap=5, hgap=5)
add!(sizer, button1)
add!(sizer, button2)
```
"""
function WxGridSizer(rows::Integer, cols::Integer; vgap::Integer = 0, hgap::Integer = 0)
    ptr = wxgridsizer_create(rows, cols, vgap, hgap)
    if ptr == C_NULL
        error("Failed to create WxGridSizer")
    end
    WxGridSizer(ptr)
end

"""
    get_cols(sizer::WxGridSizer) -> Int

Get the number of columns.
"""
function get_cols(sizer::WxGridSizer)
    wxgridsizer_getcols(sizer.ptr)
end

"""
    get_rows(sizer::WxGridSizer) -> Int

Get the number of rows.
"""
function get_rows(sizer::WxGridSizer)
    wxgridsizer_getrows(sizer.ptr)
end

"""
    get_hgap(sizer::WxGridSizer) -> Int

Get the horizontal gap between cells.
"""
function get_hgap(sizer::WxGridSizer)
    wxgridsizer_gethgap(sizer.ptr)
end

"""
    get_vgap(sizer::WxGridSizer) -> Int

Get the vertical gap between cells.
"""
function get_vgap(sizer::WxGridSizer)
    wxgridsizer_getvgap(sizer.ptr)
end

"""
    set_cols!(sizer::WxGridSizer, cols::Int)

Set the number of columns.
"""
function set_cols!(sizer::WxGridSizer, cols::Integer)
    wxgridsizer_setcols(sizer.ptr, cols)
    nothing
end

"""
    set_rows!(sizer::WxGridSizer, rows::Int)

Set the number of rows.
"""
function set_rows!(sizer::WxGridSizer, rows::Integer)
    wxgridsizer_setrows(sizer.ptr, rows)
    nothing
end

"""
    set_hgap!(sizer::WxGridSizer, gap::Int)

Set the horizontal gap between cells.
"""
function set_hgap!(sizer::WxGridSizer, gap::Integer)
    wxgridsizer_sethgap(sizer.ptr, gap)
    nothing
end

"""
    set_vgap!(sizer::WxGridSizer, gap::Int)

Set the vertical gap between cells.
"""
function set_vgap!(sizer::WxGridSizer, gap::Integer)
    wxgridsizer_setvgap(sizer.ptr, gap)
    nothing
end

# =============================================================================
# WxFlexGridSizer
# =============================================================================

"""
    WxFlexGridSizer

A grid sizer where individual rows and columns can be marked as growable,
allowing them to expand when the sizer is resized.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxFlexGridSizer C++ object
"""
mutable struct WxFlexGridSizer <: WxSizer
    ptr::Ptr{Cvoid}
end

"""
    WxFlexGridSizer(rows::Int, cols::Int; vgap::Int=0, hgap::Int=0) -> WxFlexGridSizer

Create a new flex grid sizer. Unlike WxGridSizer, individual rows/columns
can grow when the sizer is resized.

# Arguments
- `rows::Int` - Number of rows (0 means auto)
- `cols::Int` - Number of columns (0 means auto)

# Keyword Arguments
- `vgap::Int = 0` - Vertical gap between rows in pixels
- `hgap::Int = 0` - Horizontal gap between columns in pixels

# Example
```julia
sizer = WxFlexGridSizer(0, 2, vgap=5, hgap=10)
add_growable_col!(sizer, 1)  # Second column grows
add!(sizer, label)
add!(sizer, textctrl, flags=wxEXPAND[])
```
"""
function WxFlexGridSizer(rows::Integer, cols::Integer; vgap::Integer = 0, hgap::Integer = 0)
    ptr = wxflexgridsizer_create(rows, cols, vgap, hgap)
    if ptr == C_NULL
        error("Failed to create WxFlexGridSizer")
    end
    WxFlexGridSizer(ptr)
end

"""
    add_growable_col!(sizer::WxFlexGridSizer, idx::Int)

Mark a column as growable (0-based index). Growable columns expand
proportionally when the sizer is resized.
"""
function add_growable_col!(sizer::WxFlexGridSizer, idx::Integer)
    wxflexgridsizer_addgrowablecol(sizer.ptr, idx)
    nothing
end

"""
    add_growable_row!(sizer::WxFlexGridSizer, idx::Int)

Mark a row as growable (0-based index). Growable rows expand
proportionally when the sizer is resized.
"""
function add_growable_row!(sizer::WxFlexGridSizer, idx::Integer)
    wxflexgridsizer_addgrowablerow(sizer.ptr, idx)
    nothing
end

"""
    remove_growable_col!(sizer::WxFlexGridSizer, idx::Int)

Remove a column from the list of growable columns (0-based index).
"""
function remove_growable_col!(sizer::WxFlexGridSizer, idx::Integer)
    wxflexgridsizer_removegrowablecol(sizer.ptr, idx)
    nothing
end

"""
    remove_growable_row!(sizer::WxFlexGridSizer, idx::Int)

Remove a row from the list of growable rows (0-based index).
"""
function remove_growable_row!(sizer::WxFlexGridSizer, idx::Integer)
    wxflexgridsizer_removegrowablerow(sizer.ptr, idx)
    nothing
end

# WxFlexGridSizer inherits grid properties from WxGridSizer — provide the same accessors

"""
    get_cols(sizer::WxFlexGridSizer) -> Int

Get the number of columns.
"""
get_cols(sizer::WxFlexGridSizer) = wxgridsizer_getcols(sizer.ptr)

"""
    get_rows(sizer::WxFlexGridSizer) -> Int

Get the number of rows.
"""
get_rows(sizer::WxFlexGridSizer) = wxgridsizer_getrows(sizer.ptr)

"""
    get_hgap(sizer::WxFlexGridSizer) -> Int

Get the horizontal gap between cells.
"""
get_hgap(sizer::WxFlexGridSizer) = wxgridsizer_gethgap(sizer.ptr)

"""
    get_vgap(sizer::WxFlexGridSizer) -> Int

Get the vertical gap between cells.
"""
get_vgap(sizer::WxFlexGridSizer) = wxgridsizer_getvgap(sizer.ptr)

# =============================================================================
# WxGridBagSizer
# =============================================================================

"""
    WxGridBagSizer

A sizer that can lay out items in a grid with items optionally spanning
multiple rows and/or columns.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxGridBagSizer C++ object
"""
mutable struct WxGridBagSizer <: WxSizer
    ptr::Ptr{Cvoid}
end

"""
    WxGridBagSizer(; vgap::Int=0, hgap::Int=0) -> WxGridBagSizer

Create a new grid bag sizer. Unlike WxGridSizer, items specify their
position and can span multiple cells.

# Keyword Arguments
- `vgap::Int = 0` - Vertical gap between rows in pixels
- `hgap::Int = 0` - Horizontal gap between columns in pixels

# Example
```julia
sizer = WxGridBagSizer(vgap=5, hgap=5)
add!(sizer, label, row=0, col=0)
add!(sizer, textctrl, row=0, col=1, flags=wxEXPAND[])
add!(sizer, button, row=1, col=0, colspan=2, flags=wxALIGN_CENTER[])
```
"""
function WxGridBagSizer(; vgap::Integer = 0, hgap::Integer = 0)
    ptr = wxgridbagsizer_create(vgap, hgap)
    if ptr == C_NULL
        error("Failed to create WxGridBagSizer")
    end
    WxGridBagSizer(ptr)
end

"""
    set_empty_cell_size!(sizer::WxGridBagSizer, width::Int, height::Int)

Set the size used for cells with no item.
"""
function set_empty_cell_size!(sizer::WxGridBagSizer, width::Integer, height::Integer)
    wxgridbagsizer_setemptycellsize(sizer.ptr, width, height)
    nothing
end

"""
    get_empty_cell_size(sizer::WxGridBagSizer) -> Tuple{Int, Int}

Get the size used for cells with no item as (width, height).
"""
function get_empty_cell_size(sizer::WxGridBagSizer)
    wxgridbagsizer_getemptycellsize(sizer.ptr)
end

# =============================================================================
# WxWrapSizer
# =============================================================================

"""
    WxWrapSizer

A sizer that wraps its items to the next line when the available space
in the current direction is exhausted.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxWrapSizer C++ object
"""
mutable struct WxWrapSizer <: WxSizer
    ptr::Ptr{Cvoid}
end

"""
    WxWrapSizer(orientation::Symbol; flags::Int=0) -> WxWrapSizer
    WxWrapSizer(orientation::Integer; flags::Int=0) -> WxWrapSizer

Create a new wrap sizer that wraps items when space runs out.

# Arguments
- `orientation` - Either `:horizontal`/`:vertical` (Symbol) or `wxHORIZONTAL[]`/`wxVERTICAL[]` (Integer)

# Keyword Arguments
- `flags::Int = 0` - Additional flags

# Example
```julia
sizer = WxWrapSizer(:horizontal)
add!(sizer, button1)
add!(sizer, button2)
```
"""
function WxWrapSizer(orientation::Symbol; flags::Integer = 0)
    orient = if orientation == :horizontal
        wxHORIZONTAL[]
    elseif orientation == :vertical
        wxVERTICAL[]
    else
        error("Invalid orientation: $orientation (expected :horizontal or :vertical)")
    end
    ptr = wxwrapsizer_create(orient, flags)
    if ptr == C_NULL
        error("Failed to create WxWrapSizer")
    end
    WxWrapSizer(ptr)
end

function WxWrapSizer(orientation::Integer; flags::Integer = 0)
    ptr = wxwrapsizer_create(orientation, flags)
    if ptr == C_NULL
        error("Failed to create WxWrapSizer")
    end
    WxWrapSizer(ptr)
end

"""
    get_orientation(sizer::WxWrapSizer) -> Int

Get the sizer orientation.
"""
function get_orientation(sizer::WxWrapSizer)
    wxwrapsizer_getorientation(sizer.ptr)
end

"""
    set_orientation!(sizer::WxWrapSizer, orientation::Symbol)

Set the sizer orientation.
"""
function set_orientation!(sizer::WxWrapSizer, orientation::Symbol)
    orient = if orientation == :horizontal
        wxHORIZONTAL[]
    elseif orientation == :vertical
        wxVERTICAL[]
    else
        error("Invalid orientation: $orientation (expected :horizontal or :vertical)")
    end
    wxwrapsizer_setorientation(sizer.ptr, orient)
    nothing
end

# =============================================================================
# Common sizer operations (work on any WxSizer subtype)
# =============================================================================

"""
    add!(sizer::WxSizer, window::WxWindow; proportion::Int=0, flags::Int=0, border::Int=0)

Add a window to the sizer.

# Arguments
- `sizer::WxSizer` - The sizer to add to
- `window::WxWindow` - The window to add

# Keyword Arguments
- `proportion::Int = 0` - How much this item should grow relative to others (0 = fixed size)
- `flags::Int = 0` - Combination of alignment and border flags (e.g., `wxALL[] | wxEXPAND[]`)
- `border::Int = 0` - Border width in pixels (applied to sides specified by flags)

# Example
```julia
sizer = WxBoxSizer(:vertical)
add!(sizer, button, proportion=0, flags=wxALL[] | wxEXPAND[], border=5)
add!(sizer, textctrl, proportion=1, flags=wxALL[] | wxEXPAND[], border=5)
```
"""
function add!(sizer::WxSizer, window::WxWindow;
              proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    wxsizer_addwindow(sizer.ptr, window.ptr, proportion, flags, border)
    nothing
end

"""
    add!(sizer::WxSizer, child::WxSizer; proportion::Int=0, flags::Int=0, border::Int=0)

Add a child sizer to the sizer. Use this for nested layouts.

# Example
```julia
outer = WxBoxSizer(:vertical)
inner = WxBoxSizer(:horizontal)
add!(inner, button1)
add!(inner, button2)
add!(outer, inner, proportion=0, flags=wxEXPAND[])
```
"""
function add!(sizer::WxSizer, child::WxSizer;
              proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    wxsizer_addsizer(sizer.ptr, child.ptr, proportion, flags, border)
    nothing
end

"""
    add!(sizer::WxGridBagSizer, window::WxWindow; row::Int, col::Int,
         rowspan::Int=1, colspan::Int=1, flags::Int=0, border::Int=0)

Add a window to a grid bag sizer at the specified position.

# Example
```julia
sizer = WxGridBagSizer(vgap=5, hgap=5)
add!(sizer, label, row=0, col=0)
add!(sizer, textctrl, row=0, col=1, flags=wxEXPAND[])
```
"""
function add!(sizer::WxGridBagSizer, window::WxWindow;
              row::Integer, col::Integer,
              rowspan::Integer = 1, colspan::Integer = 1,
              flags::Integer = 0, border::Integer = 0)
    wxgridbagsizer_addwindow(sizer.ptr, window.ptr, row, col,
                             rowspan, colspan, flags, border)
    nothing
end

"""
    add!(sizer::WxGridBagSizer, child::WxSizer; row::Int, col::Int,
         rowspan::Int=1, colspan::Int=1, flags::Int=0, border::Int=0)

Add a child sizer to a grid bag sizer at the specified position.
"""
function add!(sizer::WxGridBagSizer, child::WxSizer;
              row::Integer, col::Integer,
              rowspan::Integer = 1, colspan::Integer = 1,
              flags::Integer = 0, border::Integer = 0)
    wxgridbagsizer_addsizer(sizer.ptr, child.ptr, row, col,
                            rowspan, colspan, flags, border)
    nothing
end

"""
    add_spacer!(sizer::WxSizer, size::Int)

Add a non-stretchable spacer of the given size (pixels).
"""
function add_spacer!(sizer::WxSizer, size::Integer)
    wxsizer_addspacer(sizer.ptr, size)
    nothing
end

"""
    add_stretch_spacer!(sizer::WxSizer, proportion::Int=1)

Add a stretchable spacer that grows proportionally to fill available space.
"""
function add_stretch_spacer!(sizer::WxSizer, proportion::Integer = 1)
    wxsizer_addstretchspacer(sizer.ptr, proportion)
    nothing
end

"""
    add_spacer!(sizer::WxGridBagSizer, width::Int, height::Int;
                row::Int, col::Int, rowspan::Int=1, colspan::Int=1,
                flags::Int=0, border::Int=0)

Add a spacer to a grid bag sizer at the specified position.
"""
function add_spacer!(sizer::WxGridBagSizer, width::Integer, height::Integer;
                     row::Integer, col::Integer,
                     rowspan::Integer = 1, colspan::Integer = 1,
                     flags::Integer = 0, border::Integer = 0)
    wxgridbagsizer_addspacer(sizer.ptr, width, height, row, col,
                             rowspan, colspan, flags, border)
    nothing
end

"""
    insert!(sizer::WxSizer, index::Int, window::WxWindow;
            proportion::Int=0, flags::Int=0, border::Int=0)

Insert a window at the given position (0-based index).
"""
function insert!(sizer::WxSizer, index::Integer, window::WxWindow;
                 proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    wxsizer_insertwindow(sizer.ptr, index, window.ptr, proportion, flags, border)
    nothing
end

"""
    insert!(sizer::WxSizer, index::Int, child::WxSizer;
            proportion::Int=0, flags::Int=0, border::Int=0)

Insert a child sizer at the given position (0-based index).
"""
function insert!(sizer::WxSizer, index::Integer, child::WxSizer;
                 proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    wxsizer_insertsizer(sizer.ptr, index, child.ptr, proportion, flags, border)
    nothing
end

"""
    prepend!(sizer::WxSizer, window::WxWindow;
             proportion::Int=0, flags::Int=0, border::Int=0)

Add a window at the beginning of the sizer.
"""
function prepend!(sizer::WxSizer, window::WxWindow;
                  proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    wxsizer_prependwindow(sizer.ptr, window.ptr, proportion, flags, border)
    nothing
end

"""
    prepend!(sizer::WxSizer, child::WxSizer;
             proportion::Int=0, flags::Int=0, border::Int=0)

Add a child sizer at the beginning of the sizer.
"""
function prepend!(sizer::WxSizer, child::WxSizer;
                  proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    wxsizer_prependsizer(sizer.ptr, child.ptr, proportion, flags, border)
    nothing
end

"""
    fit!(sizer::WxSizer, window::WxWindow)

Size the window to fit its content based on the sizer's minimum size.
"""
function fit!(sizer::WxSizer, window::WxWindow)
    wxsizer_fit(sizer.ptr, window.ptr)
    nothing
end

"""
    fit_inside!(sizer::WxSizer, window::WxWindow)

Similar to fit!, but for windows with virtual/scrollable size.
"""
function fit_inside!(sizer::WxSizer, window::WxWindow)
    wxsizer_fitinside(sizer.ptr, window.ptr)
    nothing
end

"""
    set_size_hints!(sizer::WxSizer, window::WxWindow)

Set the minimum size of the window based on the sizer and prevent the
window from being resized smaller than the sizer's minimum.
"""
function set_size_hints!(sizer::WxSizer, window::WxWindow)
    wxsizer_setsizehints(sizer.ptr, window.ptr)
    nothing
end

"""
    set_min_size!(sizer::WxSizer, width::Int, height::Int)

Set the minimum size of the sizer.
"""
function set_min_size!(sizer::WxSizer, width::Integer, height::Integer)
    wxsizer_setminsize(sizer.ptr, width, height)
    nothing
end

"""
    sizer_layout!(sizer::WxSizer)

Force the sizer to recalculate sizes and reposition its children.
"""
function sizer_layout!(sizer::WxSizer)
    wxsizer_layout(sizer.ptr)
    nothing
end

"""
    sizer_clear!(sizer::WxSizer; delete_windows::Bool=false)

Remove all items from the sizer. If delete_windows is true, also destroy
the managed windows.
"""
function sizer_clear!(sizer::WxSizer; delete_windows::Bool = false)
    wxsizer_clear(sizer.ptr, delete_windows)
    nothing
end

"""
    detach!(sizer::WxSizer, window::WxWindow) -> Bool

Detach a window from the sizer without destroying it.
"""
function detach!(sizer::WxSizer, window::WxWindow)
    wxsizer_detachwindow(sizer.ptr, window.ptr)
end

"""
    detach!(sizer::WxSizer, child::WxSizer) -> Bool

Detach a child sizer from the sizer without destroying it.
"""
function detach!(sizer::WxSizer, child::WxSizer)
    wxsizer_detachsizer(sizer.ptr, child.ptr)
end

"""
    detach!(sizer::WxSizer, index::Int) -> Bool

Detach the item at the given index (0-based).
"""
function detach!(sizer::WxSizer, index::Integer)
    wxsizer_detach(sizer.ptr, index)
end

"""
    sizer_hide!(sizer::WxSizer, window::WxWindow) -> Bool

Hide a window managed by this sizer (the space it occupies is freed).
"""
function sizer_hide!(sizer::WxSizer, window::WxWindow)
    wxsizer_hidewindow(sizer.ptr, window.ptr)
end

"""
    sizer_hide!(sizer::WxSizer, child::WxSizer) -> Bool

Hide a child sizer managed by this sizer.
"""
function sizer_hide!(sizer::WxSizer, child::WxSizer)
    wxsizer_hidesizer(sizer.ptr, child.ptr)
end

"""
    sizer_show!(sizer::WxSizer, window::WxWindow; show::Bool=true, recursive::Bool=false) -> Bool

Show or hide a window managed by this sizer.
"""
function sizer_show!(sizer::WxSizer, window::WxWindow;
                     show::Bool = true, recursive::Bool = false)
    wxsizer_showwindow(sizer.ptr, window.ptr, show, recursive)
end

"""
    sizer_show!(sizer::WxSizer, child::WxSizer; show::Bool=true, recursive::Bool=false) -> Bool

Show or hide a child sizer.
"""
function sizer_show!(sizer::WxSizer, child::WxSizer;
                     show::Bool = true, recursive::Bool = false)
    wxsizer_showsizer(sizer.ptr, child.ptr, show, recursive)
end

"""
    set_item_min_size!(sizer::WxSizer, index::Int, width::Int, height::Int)

Set the minimum size for the item at the given position (0-based).
"""
function set_item_min_size!(sizer::WxSizer, index::Integer, width::Integer, height::Integer)
    wxsizer_setitemminsize(sizer.ptr, index, width, height)
    nothing
end

"""
    set_item_min_size!(sizer::WxSizer, window::WxWindow, width::Int, height::Int)

Set the minimum size for the given window in this sizer.
"""
function set_item_min_size!(sizer::WxSizer, window::WxWindow, width::Integer, height::Integer)
    wxsizer_setitemminsizewindow(sizer.ptr, window.ptr, width, height)
    nothing
end
