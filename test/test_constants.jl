# Constants loading tests

using Test
using WxWidgets

@testset "Constants Loading" begin
    @testset "Frame Style Constants" begin
        # wxDEFAULT_FRAME_STYLE should be non-zero
        @test wxDEFAULT_FRAME_STYLE[] != 0
        @test wxDEFAULT_FRAME_STYLE[] > 0
    end

    @testset "ID Constants" begin
        # wxID_ANY should be -1
        @test wxID_ANY[] == -1

        # Other IDs should be reasonable values
        @test wxID_OK[] > 0
        @test wxID_CANCEL[] > 0
        @test wxID_OK[] != wxID_CANCEL[]
    end

    @testset "TextCtrl Style Constants" begin
        @test wxTE_MULTILINE[] != 0
        @test wxTE_READONLY[] != 0
        @test wxTE_PROCESS_TAB[] != 0
        @test wxTE_PROCESS_ENTER[] != 0
        @test wxTE_RICH[] != 0
        @test wxTE_RICH2[] != 0
        @test wxTE_PASSWORD[] != 0

        # These should all be different values
        @test wxTE_MULTILINE[] != wxTE_READONLY[]
        @test wxTE_MULTILINE[] != wxTE_PROCESS_TAB[]
    end

    @testset "Layout Constants" begin
        @test wxHORIZONTAL[] != 0
        @test wxVERTICAL[] != 0
        @test wxHORIZONTAL[] != wxVERTICAL[]

        # Alignment flags
        @test wxALL[] != 0
        @test wxEXPAND[] != 0
        @test wxALIGN_CENTER[] != 0
        @test wxLEFT[] != 0
        @test wxRIGHT[] != 0
        @test wxTOP[] != 0
        @test wxBOTTOM[] != 0
    end

    @testset "Button Style Constants" begin
        @test wxBU_EXACTFIT[] != 0
        @test wxBU_LEFT[] != 0
        @test wxBU_TOP[] != 0
        @test wxBU_RIGHT[] != 0
        @test wxBU_BOTTOM[] != 0
    end

    @testset "ComboBox Style Constants" begin
        @test wxCB_SIMPLE[] != 0
        @test wxCB_SORT[] != 0
        @test wxCB_READONLY[] != 0
        @test wxCB_DROPDOWN[] != 0
    end

    @testset "ListBox Style Constants" begin
        @test wxLB_SORT[] != 0
        @test wxLB_SINGLE[] != 0
        @test wxLB_MULTIPLE[] != 0
        @test wxLB_EXTENDED[] != 0
    end
end
