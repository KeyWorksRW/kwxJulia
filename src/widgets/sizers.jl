# High-level Sizer wrappers for layout management

# Custom REPL display for all sizer types
function Base.show(io::IO, ::MIME"text/plain", sizer::wxSizer)
    print(io, "$(typeof(sizer))(ptr=$(sizer.ptr))")
end

# =============================================================================
# wxBoxSizer
# =============================================================================

"""
    wxBoxSizer

A sizer that lays out its children in a single row or column.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxBoxSizer C++ object
"""
mutable struct wxBoxSizer <: wxSizer
    ptr::Ptr{Cvoid}
end

"""
    wxBoxSizer(orientation::Symbol) -> wxBoxSizer
    wxBoxSizer(orientation::Integer) -> wxBoxSizer

Create a new box sizer with the given orientation.

# Arguments
- `orientation` - Either `:horizontal`/`:vertical` (Symbol) or `KwxFFI.HORIZONTAL()`/`KwxFFI.VERTICAL()` (Integer)

# Example
```julia
sizer = wxBoxSizer(:vertical)
add!(sizer, button, proportion=0, flags=KwxFFI.ALL() | KwxFFI.EXPAND(), border=5)
set_sizer(frame, sizer)
```
"""
function wxBoxSizer(orientation::Symbol)
    orient = if orientation == :horizontal
        KwxFFI.HORIZONTAL()
    elseif orientation == :vertical
        KwxFFI.VERTICAL()
    else
        error("Invalid orientation: $orientation (expected :horizontal or :vertical)")
    end
    ptr = KwxFFI.wxBoxSizer_Create(Cint(orient))
    if ptr == C_NULL
        error("Failed to create wxBoxSizer")
    end
    wxBoxSizer(ptr)
end

function wxBoxSizer(orientation::Integer)
    ptr = KwxFFI.wxBoxSizer_Create(Cint(orientation))
    if ptr == C_NULL
        error("Failed to create wxBoxSizer")
    end
    wxBoxSizer(ptr)
end

"""
    get_orientation(sizer::wxBoxSizer) -> Int

Get the sizer orientation (HORIZONTAL or VERTICAL).
"""
function get_orientation(sizer::wxBoxSizer)
    Int(KwxFFI.wxBoxSizer_GetOrientation(sizer.ptr))
end

# =============================================================================
# wxGridSizer
# =============================================================================

"""
    wxGridSizer

A sizer that lays out its children in a regular grid where all cells have the same size.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxGridSizer C++ object
"""
mutable struct wxGridSizer <: wxSizer
    ptr::Ptr{Cvoid}
end

"""
    wxGridSizer(rows::Int, cols::Int; vgap::Int=0, hgap::Int=0) -> wxGridSizer

Create a new grid sizer.

# Arguments
- `rows::Int` - Number of rows (0 means determined by number of items and cols)
- `cols::Int` - Number of columns (0 means determined by number of items and rows)

# Keyword Arguments
- `vgap::Int = 0` - Vertical gap between rows in pixels
- `hgap::Int = 0` - Horizontal gap between columns in pixels

# Example
```julia
sizer = wxGridSizer(2, 3, vgap=5, hgap=5)
add!(sizer, button1)
add!(sizer, button2)
```
"""
function wxGridSizer(rows::Integer, cols::Integer; vgap::Integer = 0, hgap::Integer = 0)
    ptr = KwxFFI.wxGridSizer_Create(Cint(rows), Cint(cols), Cint(vgap), Cint(hgap))
    if ptr == C_NULL
        error("Failed to create wxGridSizer")
    end
    wxGridSizer(ptr)
end

"""
    get_cols(sizer::wxGridSizer) -> Int

Get the number of columns.
"""
function get_cols(sizer::wxGridSizer)
    Int(KwxFFI.wxGridSizer_GetCols(sizer.ptr))
end

"""
    get_rows(sizer::wxGridSizer) -> Int

Get the number of rows.
"""
function get_rows(sizer::wxGridSizer)
    Int(KwxFFI.wxGridSizer_GetRows(sizer.ptr))
end

"""
    get_hgap(sizer::wxGridSizer) -> Int

Get the horizontal gap between cells.
"""
function get_hgap(sizer::wxGridSizer)
    Int(KwxFFI.wxGridSizer_GetHGap(sizer.ptr))
end

"""
    get_vgap(sizer::wxGridSizer) -> Int

Get the vertical gap between cells.
"""
function get_vgap(sizer::wxGridSizer)
    Int(KwxFFI.wxGridSizer_GetVGap(sizer.ptr))
end

"""
    set_cols!(sizer::wxGridSizer, cols::Int)

Set the number of columns.
"""
function set_cols!(sizer::wxGridSizer, cols::Integer)
    KwxFFI.wxGridSizer_SetCols(sizer.ptr, Cint(cols))
    nothing
end

"""
    set_rows!(sizer::wxGridSizer, rows::Int)

Set the number of rows.
"""
function set_rows!(sizer::wxGridSizer, rows::Integer)
    KwxFFI.wxGridSizer_SetRows(sizer.ptr, Cint(rows))
    nothing
end

"""
    set_hgap!(sizer::wxGridSizer, gap::Int)

Set the horizontal gap between cells.
"""
function set_hgap!(sizer::wxGridSizer, gap::Integer)
    KwxFFI.wxGridSizer_SetHGap(sizer.ptr, Cint(gap))
    nothing
end

"""
    set_vgap!(sizer::wxGridSizer, gap::Int)

Set the vertical gap between cells.
"""
function set_vgap!(sizer::wxGridSizer, gap::Integer)
    KwxFFI.wxGridSizer_SetVGap(sizer.ptr, Cint(gap))
    nothing
end

# =============================================================================
# wxFlexGridSizer
# =============================================================================

"""
    wxFlexGridSizer

A grid sizer where individual rows and columns can be marked as growable,
allowing them to expand when the sizer is resized.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxFlexGridSizer C++ object
"""
mutable struct wxFlexGridSizer <: wxSizer
    ptr::Ptr{Cvoid}
end

"""
    wxFlexGridSizer(rows::Int, cols::Int; vgap::Int=0, hgap::Int=0) -> wxFlexGridSizer

Create a new flex grid sizer. Unlike wxGridSizer, individual rows/columns
can grow when the sizer is resized.

# Arguments
- `rows::Int` - Number of rows (0 means auto)
- `cols::Int` - Number of columns (0 means auto)

# Keyword Arguments
- `vgap::Int = 0` - Vertical gap between rows in pixels
- `hgap::Int = 0` - Horizontal gap between columns in pixels

# Example
```julia
sizer = wxFlexGridSizer(0, 2, vgap=5, hgap=10)
add_growable_col!(sizer, 1)  # Second column grows
add!(sizer, label)
add!(sizer, textctrl, flags=KwxFFI.EXPAND())
```
"""
function wxFlexGridSizer(rows::Integer, cols::Integer; vgap::Integer = 0, hgap::Integer = 0)
    ptr = KwxFFI.wxFlexGridSizer_Create(Cint(rows), Cint(cols), Cint(vgap), Cint(hgap))
    if ptr == C_NULL
        error("Failed to create wxFlexGridSizer")
    end
    wxFlexGridSizer(ptr)
end

"""
    add_growable_col!(sizer::wxFlexGridSizer, idx::Int; proportion::Int=0)

Mark a column as growable (0-based index). Growable columns expand
proportionally when the sizer is resized.
"""
function add_growable_col!(sizer::wxFlexGridSizer, idx::Integer; proportion::Integer = 0)
    KwxFFI.wxFlexGridSizer_AddGrowableCol(sizer.ptr, Csize_t(idx), Cint(proportion))
    nothing
end

"""
    add_growable_row!(sizer::wxFlexGridSizer, idx::Int; proportion::Int=0)

Mark a row as growable (0-based index). Growable rows expand
proportionally when the sizer is resized.
"""
function add_growable_row!(sizer::wxFlexGridSizer, idx::Integer; proportion::Integer = 0)
    KwxFFI.wxFlexGridSizer_AddGrowableRow(sizer.ptr, Csize_t(idx), Cint(proportion))
    nothing
end

"""
    remove_growable_col!(sizer::wxFlexGridSizer, idx::Int)

Remove a column from the list of growable columns (0-based index).
"""
function remove_growable_col!(sizer::wxFlexGridSizer, idx::Integer)
    KwxFFI.wxFlexGridSizer_RemoveGrowableCol(sizer.ptr, Csize_t(idx))
    nothing
end

"""
    remove_growable_row!(sizer::wxFlexGridSizer, idx::Int)

Remove a row from the list of growable rows (0-based index).
"""
function remove_growable_row!(sizer::wxFlexGridSizer, idx::Integer)
    KwxFFI.wxFlexGridSizer_RemoveGrowableRow(sizer.ptr, Csize_t(idx))
    nothing
end

# wxFlexGridSizer inherits grid properties from wxGridSizer — provide the same accessors

"""
    get_cols(sizer::wxFlexGridSizer) -> Int

Get the number of columns.
"""
get_cols(sizer::wxFlexGridSizer) = Int(KwxFFI.wxGridSizer_GetCols(sizer.ptr))

"""
    get_rows(sizer::wxFlexGridSizer) -> Int

Get the number of rows.
"""
get_rows(sizer::wxFlexGridSizer) = Int(KwxFFI.wxGridSizer_GetRows(sizer.ptr))

"""
    get_hgap(sizer::wxFlexGridSizer) -> Int

Get the horizontal gap between cells.
"""
get_hgap(sizer::wxFlexGridSizer) = Int(KwxFFI.wxGridSizer_GetHGap(sizer.ptr))

"""
    get_vgap(sizer::wxFlexGridSizer) -> Int

Get the vertical gap between cells.
"""
get_vgap(sizer::wxFlexGridSizer) = Int(KwxFFI.wxGridSizer_GetVGap(sizer.ptr))

# =============================================================================
# wxGridBagSizer
# =============================================================================

"""
    wxGridBagSizer

A sizer that can lay out items in a grid with items optionally spanning
multiple rows and/or columns.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxGridBagSizer C++ object
"""
mutable struct wxGridBagSizer <: wxSizer
    ptr::Ptr{Cvoid}
end

"""
    wxGridBagSizer(; vgap::Int=0, hgap::Int=0) -> wxGridBagSizer

Create a new grid bag sizer. Unlike wxGridSizer, items specify their
position and can span multiple cells.

# Keyword Arguments
- `vgap::Int = 0` - Vertical gap between rows in pixels
- `hgap::Int = 0` - Horizontal gap between columns in pixels

# Example
```julia
sizer = wxGridBagSizer(vgap=5, hgap=5)
add!(sizer, label, row=0, col=0)
add!(sizer, textctrl, row=0, col=1, flags=KwxFFI.EXPAND())
add!(sizer, button, row=1, col=0, colspan=2, flags=KwxFFI.ALIGN_CENTER())
```
"""
function wxGridBagSizer(; vgap::Integer = 0, hgap::Integer = 0)
    ptr = KwxFFI.wxGridBagSizer_Create(Cint(vgap), Cint(hgap))
    if ptr == C_NULL
        error("Failed to create wxGridBagSizer")
    end
    wxGridBagSizer(ptr)
end

"""
    set_empty_cell_size!(sizer::wxGridBagSizer, width::Int, height::Int)

Set the size used for cells with no item.
"""
function set_empty_cell_size!(sizer::wxGridBagSizer, width::Integer, height::Integer)
    KwxFFI.wxGridBagSizer_SetEmptyCellSize(sizer.ptr, Cint(width), Cint(height))
    nothing
end

"""
    get_empty_cell_size(sizer::wxGridBagSizer) -> Tuple{Int, Int}

Get the size used for cells with no item as (width, height).
"""
function get_empty_cell_size(sizer::wxGridBagSizer)
    w = Ref{Cint}(0)
    h = Ref{Cint}(0)
    KwxFFI.wxGridBagSizer_GetEmptyCellSize(sizer.ptr, w, h)
    (Int(w[]), Int(h[]))
end

# =============================================================================
# wxWrapSizer
# =============================================================================

"""
    wxWrapSizer

A sizer that wraps its items to the next line when the available space
in the current direction is exhausted.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxWrapSizer C++ object
"""
mutable struct wxWrapSizer <: wxSizer
    ptr::Ptr{Cvoid}
end

"""
    wxWrapSizer(orientation::Symbol; flags::Int=0) -> wxWrapSizer
    wxWrapSizer(orientation::Integer; flags::Int=0) -> wxWrapSizer

Create a new wrap sizer that wraps items when space runs out.

# Arguments
- `orientation` - Either `:horizontal`/`:vertical` (Symbol) or `KwxFFI.HORIZONTAL()`/`KwxFFI.VERTICAL()` (Integer)

# Keyword Arguments
- `flags::Int = 0` - Additional flags

# Example
```julia
sizer = wxWrapSizer(:horizontal)
add!(sizer, button1)
add!(sizer, button2)
```
"""
function wxWrapSizer(orientation::Symbol; flags::Integer = 0)
    orient = if orientation == :horizontal
        KwxFFI.HORIZONTAL()
    elseif orientation == :vertical
        KwxFFI.VERTICAL()
    else
        error("Invalid orientation: $orientation (expected :horizontal or :vertical)")
    end
    ptr = KwxFFI.wxWrapSizer_Create(Cint(orient), Cint(flags))
    if ptr == C_NULL
        error("Failed to create wxWrapSizer")
    end
    wxWrapSizer(ptr)
end

function wxWrapSizer(orientation::Integer; flags::Integer = 0)
    ptr = KwxFFI.wxWrapSizer_Create(Cint(orientation), Cint(flags))
    if ptr == C_NULL
        error("Failed to create wxWrapSizer")
    end
    wxWrapSizer(ptr)
end

"""
    get_orientation(sizer::wxWrapSizer) -> Int

Get the sizer orientation.
"""
function get_orientation(sizer::wxWrapSizer)
    Int(KwxFFI.wxWrapSizer_GetOrientation(sizer.ptr))
end

"""
    set_orientation!(sizer::wxWrapSizer, orientation::Symbol)

Set the sizer orientation.
"""
function set_orientation!(sizer::wxWrapSizer, orientation::Symbol)
    orient = if orientation == :horizontal
        KwxFFI.HORIZONTAL()
    elseif orientation == :vertical
        KwxFFI.VERTICAL()
    else
        error("Invalid orientation: $orientation (expected :horizontal or :vertical)")
    end
    KwxFFI.wxWrapSizer_SetOrientation(sizer.ptr, Cint(orient))
    nothing
end

# =============================================================================
# Common sizer operations (work on any wxSizer subtype)
# =============================================================================

"""
    add!(sizer::wxSizer, window::wxWindow; proportion::Int=0, flags::Int=0, border::Int=0)

Add a window to the sizer.

# Arguments
- `sizer::wxSizer` - The sizer to add to
- `window::wxWindow` - The window to add

# Keyword Arguments
- `proportion::Int = 0` - How much this item should grow relative to others (0 = fixed size)
- `flags::Int = 0` - Combination of alignment and border flags (e.g., `KwxFFI.ALL() | KwxFFI.EXPAND()`)
- `border::Int = 0` - Border width in pixels (applied to sides specified by flags)

# Example
```julia
sizer = wxBoxSizer(:vertical)
add!(sizer, button, proportion=0, flags=KwxFFI.ALL() | KwxFFI.EXPAND(), border=5)
add!(sizer, textctrl, proportion=1, flags=KwxFFI.ALL() | KwxFFI.EXPAND(), border=5)
```
"""
function add!(sizer::wxSizer, window::wxWindow;
              proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxSizer_AddWindow(sizer.ptr, window.ptr, Cint(proportion), Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    add!(sizer::wxSizer, child::wxSizer; proportion::Int=0, flags::Int=0, border::Int=0)

Add a child sizer to the sizer. Use this for nested layouts.

# Example
```julia
outer = wxBoxSizer(:vertical)
inner = wxBoxSizer(:horizontal)
add!(inner, button1)
add!(inner, button2)
add!(outer, inner, proportion=0, flags=KwxFFI.EXPAND())
```
"""
function add!(sizer::wxSizer, child::wxSizer;
              proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxSizer_AddSizer(sizer.ptr, child.ptr, Cint(proportion), Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    add!(sizer::wxGridBagSizer, window::wxWindow; row::Int, col::Int,
         rowspan::Int=1, colspan::Int=1, flags::Int=0, border::Int=0)

Add a window to a grid bag sizer at the specified position.

# Example
```julia
sizer = wxGridBagSizer(vgap=5, hgap=5)
add!(sizer, label, row=0, col=0)
add!(sizer, textctrl, row=0, col=1, flags=KwxFFI.EXPAND())
```
"""
function add!(sizer::wxGridBagSizer, window::wxWindow;
              row::Integer, col::Integer,
              rowspan::Integer = 1, colspan::Integer = 1,
              flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxGridBagSizer_AddWindow(sizer.ptr, window.ptr,
        Cint(row), Cint(col), Cint(rowspan), Cint(colspan),
        Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    add!(sizer::wxGridBagSizer, child::wxSizer; row::Int, col::Int,
         rowspan::Int=1, colspan::Int=1, flags::Int=0, border::Int=0)

Add a child sizer to a grid bag sizer at the specified position.
"""
function add!(sizer::wxGridBagSizer, child::wxSizer;
              row::Integer, col::Integer,
              rowspan::Integer = 1, colspan::Integer = 1,
              flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxGridBagSizer_AddSizer(sizer.ptr, child.ptr,
        Cint(row), Cint(col), Cint(rowspan), Cint(colspan),
        Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    add_spacer!(sizer::wxSizer, size::Int)

Add a non-stretchable spacer of the given size (pixels).
"""
function add_spacer!(sizer::wxSizer, size::Integer)
    KwxFFI.wxSizer_AddSpacer(sizer.ptr, Cint(size))
    nothing
end

"""
    add_stretch_spacer!(sizer::wxSizer, proportion::Int=1)

Add a stretchable spacer that grows proportionally to fill available space.
"""
function add_stretch_spacer!(sizer::wxSizer, proportion::Integer = 1)
    KwxFFI.wxSizer_AddStretchSpacer(sizer.ptr, Cint(proportion))
    nothing
end

"""
    add_spacer!(sizer::wxGridBagSizer, width::Int, height::Int;
                row::Int, col::Int, rowspan::Int=1, colspan::Int=1,
                flags::Int=0, border::Int=0)

Add a spacer to a grid bag sizer at the specified position.
"""
function add_spacer!(sizer::wxGridBagSizer, width::Integer, height::Integer;
                     row::Integer, col::Integer,
                     rowspan::Integer = 1, colspan::Integer = 1,
                     flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxGridBagSizer_AddSpacer(sizer.ptr,
        Cint(width), Cint(height),
        Cint(row), Cint(col), Cint(rowspan), Cint(colspan),
        Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    insert!(sizer::wxSizer, index::Int, window::wxWindow;
            proportion::Int=0, flags::Int=0, border::Int=0)

Insert a window at the given position (0-based index).
"""
function insert!(sizer::wxSizer, index::Integer, window::wxWindow;
                 proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxSizer_InsertWindow(sizer.ptr, Cint(index), window.ptr,
        Cint(proportion), Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    insert!(sizer::wxSizer, index::Int, child::wxSizer;
            proportion::Int=0, flags::Int=0, border::Int=0)

Insert a child sizer at the given position (0-based index).
"""
function insert!(sizer::wxSizer, index::Integer, child::wxSizer;
                 proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxSizer_InsertSizer(sizer.ptr, Cint(index), child.ptr,
        Cint(proportion), Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    prepend!(sizer::wxSizer, window::wxWindow;
             proportion::Int=0, flags::Int=0, border::Int=0)

Add a window at the beginning of the sizer.
"""
function prepend!(sizer::wxSizer, window::wxWindow;
                  proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxSizer_PrependWindow(sizer.ptr, window.ptr,
        Cint(proportion), Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    prepend!(sizer::wxSizer, child::wxSizer;
             proportion::Int=0, flags::Int=0, border::Int=0)

Add a child sizer at the beginning of the sizer.
"""
function prepend!(sizer::wxSizer, child::wxSizer;
                  proportion::Integer = 0, flags::Integer = 0, border::Integer = 0)
    KwxFFI.wxSizer_PrependSizer(sizer.ptr, child.ptr,
        Cint(proportion), Cint(flags), Cint(border), C_NULL)
    nothing
end

"""
    fit!(sizer::wxSizer, window::wxWindow)

Size the window to fit its content based on the sizer's minimum size.
"""
function fit!(sizer::wxSizer, window::wxWindow)
    KwxFFI.wxSizer_Fit(sizer.ptr, window.ptr)
    nothing
end

"""
    fit_inside!(sizer::wxSizer, window::wxWindow)

Similar to fit!, but for windows with virtual/scrollable size.
"""
function fit_inside!(sizer::wxSizer, window::wxWindow)
    KwxFFI.wxSizer_FitInside(sizer.ptr, window.ptr)
    nothing
end

"""
    set_size_hints!(sizer::wxSizer, window::wxWindow)

Set the minimum size of the window based on the sizer and prevent the
window from being resized smaller than the sizer's minimum.
"""
function set_size_hints!(sizer::wxSizer, window::wxWindow)
    KwxFFI.wxSizer_SetSizeHints(sizer.ptr, window.ptr)
    nothing
end

"""
    set_min_size!(sizer::wxSizer, width::Int, height::Int)

Set the minimum size of the sizer.
"""
function set_min_size!(sizer::wxSizer, width::Integer, height::Integer)
    KwxFFI.wxSizer_SetMinSize(sizer.ptr, Cint(width), Cint(height))
    nothing
end

"""
    sizer_layout!(sizer::wxSizer)

Force the sizer to recalculate sizes and reposition its children.
"""
function sizer_layout!(sizer::wxSizer)
    KwxFFI.wxSizer_Layout(sizer.ptr)
    nothing
end

"""
    sizer_clear!(sizer::wxSizer; delete_windows::Bool=false)

Remove all items from the sizer. If delete_windows is true, also destroy
the managed windows.
"""
function sizer_clear!(sizer::wxSizer; delete_windows::Bool = false)
    KwxFFI.wxSizer_Clear(sizer.ptr, Cint(delete_windows))
    nothing
end

"""
    detach!(sizer::wxSizer, window::wxWindow) -> Bool

Detach a window from the sizer without destroying it.
"""
function detach!(sizer::wxSizer, window::wxWindow)
    KwxFFI.wxSizer_DetachWindow(sizer.ptr, window.ptr) != 0
end

"""
    detach!(sizer::wxSizer, child::wxSizer) -> Bool

Detach a child sizer from the sizer without destroying it.
"""
function detach!(sizer::wxSizer, child::wxSizer)
    KwxFFI.wxSizer_DetachSizer(sizer.ptr, child.ptr) != 0
end

"""
    detach!(sizer::wxSizer, index::Int) -> Bool

Detach the item at the given index (0-based).
"""
function detach!(sizer::wxSizer, index::Integer)
    KwxFFI.wxSizer_Detach(sizer.ptr, Cint(index)) != 0
end

"""
    sizer_hide!(sizer::wxSizer, window::wxWindow) -> Bool

Hide a window managed by this sizer (the space it occupies is freed).
"""
function sizer_hide!(sizer::wxSizer, window::wxWindow)
    KwxFFI.wxSizer_HideWindow(sizer.ptr, window.ptr) != 0
end

"""
    sizer_hide!(sizer::wxSizer, child::wxSizer) -> Bool

Hide a child sizer managed by this sizer.
"""
function sizer_hide!(sizer::wxSizer, child::wxSizer)
    KwxFFI.wxSizer_HideSizer(sizer.ptr, child.ptr) != 0
end

"""
    sizer_show!(sizer::wxSizer, window::wxWindow; show::Bool=true, recursive::Bool=false) -> Bool

Show or hide a window managed by this sizer.
"""
function sizer_show!(sizer::wxSizer, window::wxWindow;
                     show::Bool = true, recursive::Bool = false)
    KwxFFI.wxSizer_ShowWindow(sizer.ptr, window.ptr, Cint(show), Cint(recursive)) != 0
end

"""
    sizer_show!(sizer::wxSizer, child::wxSizer; show::Bool=true, recursive::Bool=false) -> Bool

Show or hide a child sizer.
"""
function sizer_show!(sizer::wxSizer, child::wxSizer;
                     show::Bool = true, recursive::Bool = false)
    KwxFFI.wxSizer_ShowSizer(sizer.ptr, child.ptr, Cint(show), Cint(recursive)) != 0
end

"""
    set_item_min_size!(sizer::wxSizer, index::Int, width::Int, height::Int)

Set the minimum size for the item at the given position (0-based).
"""
function set_item_min_size!(sizer::wxSizer, index::Integer, width::Integer, height::Integer)
    KwxFFI.wxSizer_SetItemMinSize(sizer.ptr, Cint(index), Cint(width), Cint(height))
    nothing
end

"""
    set_item_min_size!(sizer::wxSizer, window::wxWindow, width::Int, height::Int)

Set the minimum size for the given window in this sizer.
"""
function set_item_min_size!(sizer::wxSizer, window::wxWindow, width::Integer, height::Integer)
    KwxFFI.wxSizer_SetItemMinSizeWindow(sizer.ptr, window.ptr, Cint(width), Cint(height))
    nothing
end
