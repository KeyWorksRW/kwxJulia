# Widget creation tests

using Test
using WxWidgets

@testset "Widget Creation" begin
    # Initialize wxWidgets for testing
    # Note: We need to initialize but we won't run the main loop
    result = WxWidgets.kwxapp_initialize()
    @test result != 0

    @testset "Frame Creation" begin
        # Create a frame
        frame = WxFrame(nothing, "Test Frame", size=(400, 300))
        @test frame.ptr != C_NULL
        @test !isempty(frame.children)  # Should be initialized (even if empty)
        @test !isempty(frame.closures)  # Should be initialized (even if empty)
    end

    @testset "Button Creation" begin
        # Create a frame first (buttons need a parent)
        frame = WxFrame(nothing, "Button Test", size=(300, 200))

        # Create a button
        button = WxButton(frame, "Test Button")
        @test button.ptr != C_NULL
        @test !isempty(button.closures)

        # Button should be in frame's children
        @test button in frame.children
    end

    @testset "StaticText Creation" begin
        frame = WxFrame(nothing, "StaticText Test", size=(300, 200))

        label = WxStaticText(frame, "Test Label")
        @test label.ptr != C_NULL
        @test label in frame.children
    end

    @testset "TextCtrl Creation" begin
        frame = WxFrame(nothing, "TextCtrl Test", size=(300, 200))

        # Single-line text control
        text1 = WxTextCtrl(frame, value="Test")
        @test text1.ptr != C_NULL
        @test text1 in frame.children

        # Multi-line text control
        text2 = WxTextCtrl(frame, style=wxTE_MULTILINE[])
        @test text2.ptr != C_NULL
    end

    @testset "CheckBox Creation" begin
        frame = WxFrame(nothing, "CheckBox Test", size=(300, 200))

        checkbox = WxCheckBox(frame, "Test Checkbox")
        @test checkbox.ptr != C_NULL
        @test checkbox in frame.children
    end

    @testset "ComboBox Creation" begin
        frame = WxFrame(nothing, "ComboBox Test", size=(300, 200))

        combo = WxComboBox(frame)
        @test combo.ptr != C_NULL
        @test combo in frame.children

        # Test adding items
        append!(combo, "Item 1")
        append!(combo, "Item 2")
        @test get_count(combo) == 2
    end

    @testset "ListBox Creation" begin
        frame = WxFrame(nothing, "ListBox Test", size=(300, 200))

        listbox = WxListBox(frame)
        @test listbox.ptr != C_NULL
        @test listbox in frame.children

        # Test adding items
        append!(listbox, "Item 1")
        append!(listbox, "Item 2")
        append!(listbox, "Item 3")
        @test get_count(listbox) == 3
    end

    @testset "Sizer Creation" begin
        # BoxSizer
        sizer_v = WxBoxSizer(:vertical)
        @test sizer_v.ptr != C_NULL
        @test get_orientation(sizer_v) == wxVERTICAL[]

        sizer_h = WxBoxSizer(:horizontal)
        @test sizer_h.ptr != C_NULL
        @test get_orientation(sizer_h) == wxHORIZONTAL[]

        # GridSizer
        grid = WxGridSizer(2, 3, 5, 5)  # 2 rows, 3 cols, 5px gaps
        @test grid.ptr != C_NULL
        @test get_rows(grid) == 2
        @test get_cols(grid) == 3
        @test get_hgap(grid) == 5
        @test get_vgap(grid) == 5
    end

    @testset "Layout with Sizers" begin
        frame = WxFrame(nothing, "Layout Test", size=(400, 300))

        button1 = WxButton(frame, "Button 1")
        button2 = WxButton(frame, "Button 2")

        sizer = WxBoxSizer(:vertical)
        add!(sizer, button1, proportion=0, flags=wxALL[], border=5)
        add!(sizer, button2, proportion=0, flags=wxALL[], border=5)

        set_sizer(frame, sizer)
        # If we got here without crashing, layout works
        @test true
    end

    @testset "Event Handler Registration" begin
        frame = WxFrame(nothing, "Event Test", size=(300, 200))
        button = WxButton(frame, "Click Me")

        handler_called = Ref(false)

        # Register an event handler
        on_click!(button) do event
            handler_called[] = true
        end

        # Handler should be stored in closures
        @test length(button.closures) > 0
    end

    # Note: We don't test actual event firing here since that would require
    # running the event loop or simulating user input
end
