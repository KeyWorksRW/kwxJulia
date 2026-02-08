# Raw FFI declarations for layout sizers:
# wxSizer (base), wxBoxSizer, wxGridSizer, wxFlexGridSizer, wxGridBagSizer, wxWrapSizer

# =============================================================================
# wxSizer (base class)
# =============================================================================

"""
    wxsizer_addwindow(sizer, window, proportion, flag, border, userData) -> Cvoid

Add a window to the sizer.
"""
function wxsizer_addwindow(sizer::Ptr{Cvoid}, window::Ptr{Cvoid},
                           proportion::Integer, flag::Integer, border::Integer,
                           userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxSizer_AddWindow))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid},
        proportion::Cint,
        flag::Cint,
        border::Cint,
        userData::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_addsizer(sizer, child_sizer, proportion, flag, border, userData) -> Cvoid

Add a child sizer to the sizer.
"""
function wxsizer_addsizer(sizer::Ptr{Cvoid}, child_sizer::Ptr{Cvoid},
                          proportion::Integer, flag::Integer, border::Integer,
                          userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxSizer_AddSizer))(
        sizer::Ptr{Cvoid},
        child_sizer::Ptr{Cvoid},
        proportion::Cint,
        flag::Cint,
        border::Cint,
        userData::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_addspacer(sizer, width, height, proportion, flag, border, userData) -> Cvoid

Add a spacer (empty space) to the sizer.
"""
function wxsizer_add(sizer::Ptr{Cvoid}, width::Integer, height::Integer,
                     proportion::Integer, flag::Integer, border::Integer,
                     userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxSizer_Add))(
        sizer::Ptr{Cvoid},
        width::Cint, height::Cint,
        proportion::Cint,
        flag::Cint,
        border::Cint,
        userData::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_addspacer_simple(sizer, size) -> Cvoid

Add a non-stretchable spacer of the given size.
"""
function wxsizer_addspacer(sizer::Ptr{Cvoid}, size::Integer)
    @ccall $(ffi(:wxSizer_AddSpacer))(
        sizer::Ptr{Cvoid},
        size::Cint
    )::Cvoid
end

"""
    wxsizer_addstretchspacer(sizer, proportion) -> Cvoid

Add a stretchable spacer.
"""
function wxsizer_addstretchspacer(sizer::Ptr{Cvoid}, proportion::Integer = 1)
    @ccall $(ffi(:wxSizer_AddStretchSpacer))(
        sizer::Ptr{Cvoid},
        proportion::Cint
    )::Cvoid
end

"""
    wxsizer_insertwindow(sizer, before, window, proportion, flag, border, userData) -> Cvoid

Insert a window at the given position.
"""
function wxsizer_insertwindow(sizer::Ptr{Cvoid}, before::Integer, window::Ptr{Cvoid},
                              proportion::Integer, flag::Integer, border::Integer,
                              userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxSizer_InsertWindow))(
        sizer::Ptr{Cvoid},
        before::Cint,
        window::Ptr{Cvoid},
        proportion::Cint,
        flag::Cint,
        border::Cint,
        userData::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_insertsizer(sizer, before, child_sizer, proportion, flag, border, userData) -> Cvoid

Insert a child sizer at the given position.
"""
function wxsizer_insertsizer(sizer::Ptr{Cvoid}, before::Integer, child_sizer::Ptr{Cvoid},
                             proportion::Integer, flag::Integer, border::Integer,
                             userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxSizer_InsertSizer))(
        sizer::Ptr{Cvoid},
        before::Cint,
        child_sizer::Ptr{Cvoid},
        proportion::Cint,
        flag::Cint,
        border::Cint,
        userData::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_insertspacer(sizer, index, size) -> Ptr{Cvoid}

Insert a spacer at the given position.
"""
function wxsizer_insertspacer(sizer::Ptr{Cvoid}, index::Integer, size::Integer)
    @ccall $(ffi(:wxSizer_InsertSpacer))(
        sizer::Ptr{Cvoid},
        index::Cint,
        size::Cint
    )::Ptr{Cvoid}
end

"""
    wxsizer_insertstretchspacer(sizer, index, proportion) -> Ptr{Cvoid}

Insert a stretchable spacer at the given position.
"""
function wxsizer_insertstretchspacer(sizer::Ptr{Cvoid}, index::Integer, proportion::Integer = 1)
    @ccall $(ffi(:wxSizer_InsertStretchSpacer))(
        sizer::Ptr{Cvoid},
        index::Cint,
        proportion::Cint
    )::Ptr{Cvoid}
end

"""
    wxsizer_prependwindow(sizer, window, proportion, flag, border, userData) -> Cvoid

Prepend a window to the beginning of the sizer.
"""
function wxsizer_prependwindow(sizer::Ptr{Cvoid}, window::Ptr{Cvoid},
                               proportion::Integer, flag::Integer, border::Integer,
                               userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxSizer_PrependWindow))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid},
        proportion::Cint,
        flag::Cint,
        border::Cint,
        userData::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_prependsizer(sizer, child_sizer, proportion, flag, border, userData) -> Cvoid

Prepend a child sizer to the beginning of the sizer.
"""
function wxsizer_prependsizer(sizer::Ptr{Cvoid}, child_sizer::Ptr{Cvoid},
                              proportion::Integer, flag::Integer, border::Integer,
                              userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxSizer_PrependSizer))(
        sizer::Ptr{Cvoid},
        child_sizer::Ptr{Cvoid},
        proportion::Cint,
        flag::Cint,
        border::Cint,
        userData::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_prependspacer(sizer, size) -> Ptr{Cvoid}

Prepend a spacer to the beginning of the sizer.
"""
function wxsizer_prependspacer(sizer::Ptr{Cvoid}, size::Integer)
    @ccall $(ffi(:wxSizer_PrependSpacer))(
        sizer::Ptr{Cvoid},
        size::Cint
    )::Ptr{Cvoid}
end

"""
    wxsizer_prependstretchspacer(sizer, proportion) -> Ptr{Cvoid}

Prepend a stretchable spacer to the beginning of the sizer.
"""
function wxsizer_prependstretchspacer(sizer::Ptr{Cvoid}, proportion::Integer = 1)
    @ccall $(ffi(:wxSizer_PrependStretchSpacer))(
        sizer::Ptr{Cvoid},
        proportion::Cint
    )::Ptr{Cvoid}
end

"""
    wxsizer_fit(sizer, window) -> Cvoid

Size the window to fit its content. Sets the window size to the sizer's minimum size.
"""
function wxsizer_fit(sizer::Ptr{Cvoid}, window::Ptr{Cvoid})
    @ccall $(ffi(:wxSizer_Fit))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_fitinside(sizer, window) -> Cvoid

Like Fit, but for virtual-scrollable windows.
"""
function wxsizer_fitinside(sizer::Ptr{Cvoid}, window::Ptr{Cvoid})
    @ccall $(ffi(:wxSizer_FitInside))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_setsizehints(sizer, window) -> Cvoid

Set the minimum size of the window based on the sizer's minimum size.
Also prevents the window from being resized smaller.
"""
function wxsizer_setsizehints(sizer::Ptr{Cvoid}, window::Ptr{Cvoid})
    @ccall $(ffi(:wxSizer_SetSizeHints))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxsizer_setminsize(sizer, width, height) -> Cvoid

Set the minimum size of the sizer.
"""
function wxsizer_setminsize(sizer::Ptr{Cvoid}, width::Integer, height::Integer)
    @ccall $(ffi(:wxSizer_SetMinSize))(
        sizer::Ptr{Cvoid},
        width::Cint, height::Cint
    )::Cvoid
end

"""
    wxsizer_layout(sizer) -> Cvoid

Force the sizer to recalculate sizes and reposition its children.
"""
function wxsizer_layout(sizer::Ptr{Cvoid})
    @ccall $(ffi(:wxSizer_Layout))(sizer::Ptr{Cvoid})::Cvoid
end

"""
    wxsizer_clear(sizer, delete_windows) -> Cvoid

Remove all items from the sizer. If delete_windows is true, also destroy window children.
"""
function wxsizer_clear(sizer::Ptr{Cvoid}, delete_windows::Bool = false)
    @ccall $(ffi(:wxSizer_Clear))(
        sizer::Ptr{Cvoid},
        delete_windows::Cint
    )::Cvoid
end

"""
    wxsizer_detachwindow(sizer, window) -> Bool

Detach a window from the sizer without destroying it.
"""
function wxsizer_detachwindow(sizer::Ptr{Cvoid}, window::Ptr{Cvoid})
    (@ccall $(ffi(:wxSizer_DetachWindow))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid}
    )::Cint) != 0
end

"""
    wxsizer_detachsizer(sizer, child_sizer) -> Bool

Detach a child sizer from the sizer without destroying it.
"""
function wxsizer_detachsizer(sizer::Ptr{Cvoid}, child_sizer::Ptr{Cvoid})
    (@ccall $(ffi(:wxSizer_DetachSizer))(
        sizer::Ptr{Cvoid},
        child_sizer::Ptr{Cvoid}
    )::Cint) != 0
end

"""
    wxsizer_detach(sizer, index) -> Bool

Detach the item at the given index.
"""
function wxsizer_detach(sizer::Ptr{Cvoid}, index::Integer)
    (@ccall $(ffi(:wxSizer_Detach))(
        sizer::Ptr{Cvoid},
        index::Cint
    )::Cint) != 0
end

"""
    wxsizer_hidewindow(sizer, window) -> Bool

Hide a window managed by this sizer.
"""
function wxsizer_hidewindow(sizer::Ptr{Cvoid}, window::Ptr{Cvoid})
    (@ccall $(ffi(:wxSizer_HideWindow))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid}
    )::Cint) != 0
end

"""
    wxsizer_hidesizer(sizer, child_sizer) -> Bool

Hide a child sizer managed by this sizer.
"""
function wxsizer_hidesizer(sizer::Ptr{Cvoid}, child_sizer::Ptr{Cvoid})
    (@ccall $(ffi(:wxSizer_HideSizer))(
        sizer::Ptr{Cvoid},
        child_sizer::Ptr{Cvoid}
    )::Cint) != 0
end

"""
    wxsizer_hide(sizer, index) -> Bool

Hide the item at the given index.
"""
function wxsizer_hide(sizer::Ptr{Cvoid}, index::Integer)
    (@ccall $(ffi(:wxSizer_Hide))(
        sizer::Ptr{Cvoid},
        index::Cint
    )::Cint) != 0
end

"""
    wxsizer_showwindow(sizer, window, show, recursive) -> Bool

Show or hide a window managed by this sizer.
"""
function wxsizer_showwindow(sizer::Ptr{Cvoid}, window::Ptr{Cvoid},
                            show::Bool = true, recursive::Bool = false)
    (@ccall $(ffi(:wxSizer_ShowWindow))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid},
        show::Cint,
        recursive::Cint
    )::Cint) != 0
end

"""
    wxsizer_showsizer(sizer, child_sizer, show, recursive) -> Bool

Show or hide a child sizer managed by this sizer.
"""
function wxsizer_showsizer(sizer::Ptr{Cvoid}, child_sizer::Ptr{Cvoid},
                           show::Bool = true, recursive::Bool = false)
    (@ccall $(ffi(:wxSizer_ShowSizer))(
        sizer::Ptr{Cvoid},
        child_sizer::Ptr{Cvoid},
        show::Cint,
        recursive::Cint
    )::Cint) != 0
end

"""
    wxsizer_isshown(sizer, index) -> Bool

Check if the item at the given index is shown.
"""
function wxsizer_isshown(sizer::Ptr{Cvoid}, index::Integer)
    (@ccall $(ffi(:wxSizer_IsShown))(
        sizer::Ptr{Cvoid},
        index::Cint
    )::Cint) != 0
end

"""
    wxsizer_setitemminsize(sizer, pos, width, height) -> Cvoid

Set the minimum size for the item at the given position.
"""
function wxsizer_setitemminsize(sizer::Ptr{Cvoid}, pos::Integer, width::Integer, height::Integer)
    @ccall $(ffi(:wxSizer_SetItemMinSize))(
        sizer::Ptr{Cvoid},
        pos::Cint,
        width::Cint, height::Cint
    )::Cvoid
end

"""
    wxsizer_setitemminsizewindow(sizer, window, width, height) -> Cvoid

Set the minimum size for the given window in this sizer.
"""
function wxsizer_setitemminsizewindow(sizer::Ptr{Cvoid}, window::Ptr{Cvoid},
                                      width::Integer, height::Integer)
    @ccall $(ffi(:wxSizer_SetItemMinSizeWindow))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid},
        width::Cint, height::Cint
    )::Cvoid
end

"""
    wxsizer_getcontainingwindow(sizer) -> Ptr{Cvoid}

Get the window this sizer is used in.
"""
function wxsizer_getcontainingwindow(sizer::Ptr{Cvoid})
    @ccall $(ffi(:wxSizer_GetContainingWindow))(sizer::Ptr{Cvoid})::Ptr{Cvoid}
end

# =============================================================================
# wxBoxSizer
# =============================================================================

"""
    wxboxsizer_create(orient) -> Ptr{Cvoid}

Create a new wxBoxSizer. orient is wxHORIZONTAL or wxVERTICAL.
"""
function wxboxsizer_create(orient::Integer)
    @ccall $(ffi(:wxBoxSizer_Create))(orient::Cint)::Ptr{Cvoid}
end

"""
    wxboxsizer_getorientation(sizer) -> Int

Get the sizer orientation (wxHORIZONTAL or wxVERTICAL).
"""
function wxboxsizer_getorientation(sizer::Ptr{Cvoid})
    Int(@ccall $(ffi(:wxBoxSizer_GetOrientation))(sizer::Ptr{Cvoid})::Cint)
end

# =============================================================================
# wxGridSizer
# =============================================================================

"""
    wxgridsizer_create(rows, cols, vgap, hgap) -> Ptr{Cvoid}

Create a new wxGridSizer.
"""
function wxgridsizer_create(rows::Integer, cols::Integer, vgap::Integer, hgap::Integer)
    @ccall $(ffi(:wxGridSizer_Create))(
        rows::Cint, cols::Cint,
        vgap::Cint, hgap::Cint
    )::Ptr{Cvoid}
end

"""
    wxgridsizer_getcols(sizer) -> Int

Get the number of columns.
"""
function wxgridsizer_getcols(sizer::Ptr{Cvoid})
    Int(@ccall $(ffi(:wxGridSizer_GetCols))(sizer::Ptr{Cvoid})::Cint)
end

"""
    wxgridsizer_getrows(sizer) -> Int

Get the number of rows.
"""
function wxgridsizer_getrows(sizer::Ptr{Cvoid})
    Int(@ccall $(ffi(:wxGridSizer_GetRows))(sizer::Ptr{Cvoid})::Cint)
end

"""
    wxgridsizer_gethgap(sizer) -> Int

Get the horizontal gap between cells.
"""
function wxgridsizer_gethgap(sizer::Ptr{Cvoid})
    Int(@ccall $(ffi(:wxGridSizer_GetHGap))(sizer::Ptr{Cvoid})::Cint)
end

"""
    wxgridsizer_getvgap(sizer) -> Int

Get the vertical gap between cells.
"""
function wxgridsizer_getvgap(sizer::Ptr{Cvoid})
    Int(@ccall $(ffi(:wxGridSizer_GetVGap))(sizer::Ptr{Cvoid})::Cint)
end

"""
    wxgridsizer_setcols(sizer, cols) -> Cvoid

Set the number of columns.
"""
function wxgridsizer_setcols(sizer::Ptr{Cvoid}, cols::Integer)
    @ccall $(ffi(:wxGridSizer_SetCols))(sizer::Ptr{Cvoid}, cols::Cint)::Cvoid
end

"""
    wxgridsizer_setrows(sizer, rows) -> Cvoid

Set the number of rows.
"""
function wxgridsizer_setrows(sizer::Ptr{Cvoid}, rows::Integer)
    @ccall $(ffi(:wxGridSizer_SetRows))(sizer::Ptr{Cvoid}, rows::Cint)::Cvoid
end

"""
    wxgridsizer_sethgap(sizer, gap) -> Cvoid

Set the horizontal gap between cells.
"""
function wxgridsizer_sethgap(sizer::Ptr{Cvoid}, gap::Integer)
    @ccall $(ffi(:wxGridSizer_SetHGap))(sizer::Ptr{Cvoid}, gap::Cint)::Cvoid
end

"""
    wxgridsizer_setvgap(sizer, gap) -> Cvoid

Set the vertical gap between cells.
"""
function wxgridsizer_setvgap(sizer::Ptr{Cvoid}, gap::Integer)
    @ccall $(ffi(:wxGridSizer_SetVGap))(sizer::Ptr{Cvoid}, gap::Cint)::Cvoid
end

# =============================================================================
# wxFlexGridSizer
# =============================================================================

"""
    wxflexgridsizer_create(rows, cols, vgap, hgap) -> Ptr{Cvoid}

Create a new wxFlexGridSizer.
"""
function wxflexgridsizer_create(rows::Integer, cols::Integer, vgap::Integer, hgap::Integer)
    @ccall $(ffi(:wxFlexGridSizer_Create))(
        rows::Cint, cols::Cint,
        vgap::Cint, hgap::Cint
    )::Ptr{Cvoid}
end

"""
    wxflexgridsizer_addgrowablecol(sizer, idx) -> Cvoid

Mark a column as growable (can expand when the sizer is resized).
"""
function wxflexgridsizer_addgrowablecol(sizer::Ptr{Cvoid}, idx::Integer)
    @ccall $(ffi(:wxFlexGridSizer_AddGrowableCol))(
        sizer::Ptr{Cvoid},
        idx::Csize_t
    )::Cvoid
end

"""
    wxflexgridsizer_addgrowablerow(sizer, idx) -> Cvoid

Mark a row as growable (can expand when the sizer is resized).
"""
function wxflexgridsizer_addgrowablerow(sizer::Ptr{Cvoid}, idx::Integer)
    @ccall $(ffi(:wxFlexGridSizer_AddGrowableRow))(
        sizer::Ptr{Cvoid},
        idx::Csize_t
    )::Cvoid
end

"""
    wxflexgridsizer_removegrowablecol(sizer, idx) -> Cvoid

Remove a column from the list of growable columns.
"""
function wxflexgridsizer_removegrowablecol(sizer::Ptr{Cvoid}, idx::Integer)
    @ccall $(ffi(:wxFlexGridSizer_RemoveGrowableCol))(
        sizer::Ptr{Cvoid},
        idx::Csize_t
    )::Cvoid
end

"""
    wxflexgridsizer_removegrowablerow(sizer, idx) -> Cvoid

Remove a row from the list of growable rows.
"""
function wxflexgridsizer_removegrowablerow(sizer::Ptr{Cvoid}, idx::Integer)
    @ccall $(ffi(:wxFlexGridSizer_RemoveGrowableRow))(
        sizer::Ptr{Cvoid},
        idx::Csize_t
    )::Cvoid
end

# =============================================================================
# wxGridBagSizer
# =============================================================================

"""
    wxgridbagsizer_create(vgap, hgap) -> Ptr{Cvoid}

Create a new wxGridBagSizer.
"""
function wxgridbagsizer_create(vgap::Integer, hgap::Integer)
    @ccall $(ffi(:wxGridBagSizer_Create))(
        vgap::Cint, hgap::Cint
    )::Ptr{Cvoid}
end

"""
    wxgridbagsizer_addwindow(sizer, window, row, col, rowspan, colspan, flag, border, userData) -> Ptr{Cvoid}

Add a window at the specified grid position with optional spanning.
"""
function wxgridbagsizer_addwindow(sizer::Ptr{Cvoid}, window::Ptr{Cvoid},
                                  row::Integer, col::Integer,
                                  rowspan::Integer, colspan::Integer,
                                  flag::Integer, border::Integer,
                                  userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxGridBagSizer_AddWindow))(
        sizer::Ptr{Cvoid},
        window::Ptr{Cvoid},
        row::Cint, col::Cint,
        rowspan::Cint, colspan::Cint,
        flag::Cint, border::Cint,
        userData::Ptr{Cvoid}
    )::Ptr{Cvoid}
end

"""
    wxgridbagsizer_addsizer(sizer, child_sizer, row, col, rowspan, colspan, flag, border, userData) -> Ptr{Cvoid}

Add a child sizer at the specified grid position with optional spanning.
"""
function wxgridbagsizer_addsizer(sizer::Ptr{Cvoid}, child_sizer::Ptr{Cvoid},
                                 row::Integer, col::Integer,
                                 rowspan::Integer, colspan::Integer,
                                 flag::Integer, border::Integer,
                                 userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxGridBagSizer_AddSizer))(
        sizer::Ptr{Cvoid},
        child_sizer::Ptr{Cvoid},
        row::Cint, col::Cint,
        rowspan::Cint, colspan::Cint,
        flag::Cint, border::Cint,
        userData::Ptr{Cvoid}
    )::Ptr{Cvoid}
end

"""
    wxgridbagsizer_addspacer(sizer, width, height, row, col, rowspan, colspan, flag, border, userData) -> Ptr{Cvoid}

Add a spacer at the specified grid position with optional spanning.
"""
function wxgridbagsizer_addspacer(sizer::Ptr{Cvoid}, width::Integer, height::Integer,
                                  row::Integer, col::Integer,
                                  rowspan::Integer, colspan::Integer,
                                  flag::Integer, border::Integer,
                                  userData::Ptr{Cvoid} = C_NULL)
    @ccall $(ffi(:wxGridBagSizer_AddSpacer))(
        sizer::Ptr{Cvoid},
        width::Cint, height::Cint,
        row::Cint, col::Cint,
        rowspan::Cint, colspan::Cint,
        flag::Cint, border::Cint,
        userData::Ptr{Cvoid}
    )::Ptr{Cvoid}
end

"""
    wxgridbagsizer_setemptycellsize(sizer, width, height) -> Cvoid

Set the size used for cells with no item.
"""
function wxgridbagsizer_setemptycellsize(sizer::Ptr{Cvoid}, width::Integer, height::Integer)
    @ccall $(ffi(:wxGridBagSizer_SetEmptyCellSize))(
        sizer::Ptr{Cvoid},
        width::Cint, height::Cint
    )::Cvoid
end

"""
    wxgridbagsizer_getemptycellsize(sizer) -> Tuple{Int, Int}

Get the size used for cells with no item.
"""
function wxgridbagsizer_getemptycellsize(sizer::Ptr{Cvoid})
    width = Ref{Cint}(0)
    height = Ref{Cint}(0)
    @ccall $(ffi(:wxGridBagSizer_GetEmptyCellSize))(
        sizer::Ptr{Cvoid},
        width::Ptr{Cint},
        height::Ptr{Cint}
    )::Cvoid
    (Int(width[]), Int(height[]))
end

"""
    wxgridbagsizer_finditematposition(sizer, row, col) -> Ptr{Cvoid}

Find the sizer item at the given grid position.
"""
function wxgridbagsizer_finditematposition(sizer::Ptr{Cvoid}, row::Integer, col::Integer)
    @ccall $(ffi(:wxGridBagSizer_FindItemAtPosition))(
        sizer::Ptr{Cvoid},
        row::Cint, col::Cint
    )::Ptr{Cvoid}
end

# =============================================================================
# wxWrapSizer
# =============================================================================

"""
    wxwrapsizer_create(orient, flags) -> Ptr{Cvoid}

Create a new wxWrapSizer.
"""
function wxwrapsizer_create(orient::Integer, flags::Integer = 0)
    @ccall $(ffi(:wxWrapSizer_Create))(
        orient::Cint,
        flags::Cint
    )::Ptr{Cvoid}
end

"""
    wxwrapsizer_getorientation(sizer) -> Int

Get the sizer orientation.
"""
function wxwrapsizer_getorientation(sizer::Ptr{Cvoid})
    Int(@ccall $(ffi(:wxWrapSizer_GetOrientation))(sizer::Ptr{Cvoid})::Cint)
end

"""
    wxwrapsizer_setorientation(sizer, orient) -> Cvoid

Set the sizer orientation.
"""
function wxwrapsizer_setorientation(sizer::Ptr{Cvoid}, orient::Integer)
    @ccall $(ffi(:wxWrapSizer_SetOrientation))(
        sizer::Ptr{Cvoid},
        orient::Cint
    )::Cvoid
end
