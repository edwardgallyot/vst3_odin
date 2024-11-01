package vst3

FUnknownVtbl :: struct #packed {
    query_interface: proc "c" (rawptr, cstring, ^rawptr) -> Result,
    add_ref: proc "c" (rawptr) -> u32,
    release: proc "c" (rawptr) -> u32,
}

FUnknown :: struct #packed {
    using vtbl: ^FUnknownVtbl 
}

FUnknown_iid :: "00000000-0000-0000-c000-000000000046"

IPlugViewContentScaleSupportVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_content_scale_factor: proc "c"(rawptr, f32) -> Result,
}

IPlugViewContentScaleSupport :: struct #packed {
    using vtbl: ^IPlugViewContentScaleSupportVtbl,
}

IPlugViewContentScaleSupport_iid :: "65ed9690-8ac4-4525-8aad-ef7a72ea703f"

IPlugViewVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    is_platform_type_supported: proc "c" (rawptr, cstring) -> Result,
    attached: proc "c" (rawptr, rawptr, cstring) -> Result,
    removed: proc "c" (rawptr) -> Result,
    on_wheel: proc "c" (rawptr, f32) -> Result,
    on_key_down: proc "c" (rawptr, u16, i16, i16) -> Result,
    on_key_up: proc "c" (rawptr, u16, i16, i16) -> Result,
    get_size: proc "c" (rawptr, ^ViewRect) -> Result,
    on_size: proc "c" (rawptr, ^ViewRect) -> Result,
    on_focus: proc "c" (rawptr, u8) -> Result,
    set_frame: proc "c" (rawptr, ^IPlugFrame) -> Result,
    can_resize: proc "c" (rawptr) -> Result,
    check_size_constraint: proc "c" (rawptr, ^ViewRect) -> Result,
}

IPlugView :: struct #packed {
    using vtbl: IPlugViewVtbl,
}

IPlugView_iid :: "5bc32507-d060-49ea-a615-1b522b755b29"

IPlugFrameVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    resize_view: proc "c" (rawptr, ^IPlugView, ^ViewRect) -> Result,
}

IPlugFrame :: struct #packed {
    using vtbl: ^IPlugFrameVtbl,
}

IPlugFrame_iid :: "367faf01-afa9-4693-8d4d-a2a0ed0882a3"

IBStreamVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    read: proc "c" (rawptr, rawptr, i32, ^i32) -> Result,
    write: proc "c" (rawptr, rawptr, i32, ^i32) -> Result,
    seek: proc "c" (rawptr, i64, IStreamSeekMode, ^i64) -> Result,
    tell: proc "c" (rawptr, ^i64) -> Result,
}

IBStream :: struct #packed {
    using vtbl: ^IBStreamVtbl,
} 

IBStream_iid :: "c3bf6ea2-3099-4752-9b6b-f9901ee33e9b"

ISizeableStreamVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_stream_size: proc "c" (rawptr, ^i64) -> Result,
    set_stream_size: proc "c" (rawptr, i64) -> Result,
}

ISizeableStream :: struct #packed {
    using vtbl: ^ISizeableStreamVtbl,
}

ISizeableStream_iid :: "04f9549e-e02f-4e6e-87e8-6a8747f4e17f"


INoteExpressionControllerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_note_expression_count: proc "c" (rawptr, i32, i16) -> i32,
    get_note_expression_info: proc "c" (rawptr, i32, i16, i32, ^NoteExpressionTypeInfo) -> Result,
    get_note_expression_string_by_value: proc "c" (rawptr, i32, i16, NoteExpressionTypeID, ^NoteExpressionTypeInfo, f64, String128) -> Result,
    get_note_expression_value_by_string: proc "c" (rawptr, i32, i16, NoteExpressionTypeID, ^u16, f64) -> Result,
}

INoteExpressionController :: struct #packed {
    using vtbl: ^INoteExpressionControllerVtbl,
}

INoteExpressionController_iid :: "b7f8f859-4123-4872-9116-95814f3721a3"

IKeyswitchControllerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_keyswitch_count: proc "c" (rawptr, i32, i16) -> i32,
    get_keyswitch_info: proc "c" (rawptr, i32, i16, i32, ^KeyswitchInfo) -> Result,
}

IKeyswitchController :: struct #packed {
    using vtbl: ^IKeyswitchControllerVtbl,
}

IKeyswitchController_iid :: "1f2f76d3-bffb-4b96-b995-27a55ebccef4"

INoteExpressionPhysicalUIMappingVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_physical_ui_mapping: proc "c" (rawptr, i32, i16, ^PhysicalUIMapList) -> Result,
}

INoteExpressionPhysicalUIMapping :: struct #packed {
    using vtbl: ^INoteExpressionPhysicalUIMappingVtbl,
}

INoteExpressionPhysicalUIMapping_iid :: "b03078ff-94d2-4ac8-90cc-d303d4133324"


IPluginBaseVtbl :: struct #packed {
    using unknown: FUnknownVtbl,

    initialize: proc "c" (rawptr, ^FUnknown) -> Result,
    terminate: proc "c" (rawptr) -> Result,
} 

IPluginBase :: struct #packed {
    using vtbl: ^IPluginBaseVtbl,
}

IPluginBase_iid :: "22888ddb-156e-45ae-8358-b34808190625"

IPluginFactoryVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_factory_info: proc "c" (rawptr, ^PFactoryInfo) ->  Result,
    count_classes: proc "c" (rawptr) -> i32,
    get_class_info: proc "c" (rawptr, i32, ^PClassInfo) -> Result,
    create_instance: proc "c" (rawptr, cstring, cstring, ^rawptr) -> Result,
} 

IPluginFactory :: struct #packed {
    using vtbl: ^IPluginFactoryVtbl,
} 

IPluginFactory_iid :: "7a4d811c-5211-4a1f-aed9-d2ee0b43bf9f"

IPluginFactory2Vtbl :: struct #packed {
    using factory: IPluginFactoryVtbl,
    get_class_info_2: proc "c" (rawptr, i32, ^PClassInfo2) -> Result,
}

IPluginFactory2 :: struct #packed {
    using vtbl: ^IPluginFactory2Vtbl,
} 

IPluginFactory2_iid :: "0007b650-f24b-4c0b-a464-edb9f00b2abb"

IPluginFactory3Vtbl :: struct #packed {
    using factory_2: IPluginFactory2Vtbl,
    get_class_info_unicode: proc "c" (rawptr, i32, ^PClassInfoW) -> Result,
    set_host_context: proc "c" (rawptr, ^FUnknown) -> Result
}

IPluginFactory3 :: struct #packed {
    using vtbl: ^IPluginFactory3Vtbl,
}

IPluginFactory3_iid :: "4555a2ab-c123-4e57-9b12-291036878931"

IComponentVtbl :: struct #packed {
    using plugin_base: IPluginBaseVtbl,
    get_controller_class_id: proc "c" (rawptr, TUID) -> Result,
    set_io_mode: proc "c" (rawptr, IoMode) -> Result,
    get_bus_count: proc "c" (rawptr, MediaType, BusDirection) -> i32,
    get_bus_info: proc "c" (rawptr, MediaType, BusDirection, i32, ^BusInfo) -> Result,
    get_routing_info: proc "c" (rawptr, ^RoutingInfo, ^RoutingInfo) -> Result,
    activate_bus: proc "c" (rawptr, MediaType, BusDirection, i32, u8) -> Result,
    set_active: proc "c" (rawptr, u8) -> Result,
    set_state: proc "c" (rawptr, ^IBStream) -> Result,
    get_state: proc "c" (rawptr, ^IBStream) -> Result,
}

IComponent :: struct #packed {
    using vtbl: ^IComponentVtbl
}

IComponent_iid :: "e831ff31-f2d5-4301-928e-bbee25697802"

IAttributeListVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_int: proc "c" (rawptr, cstring, i64) -> Result,
    get_int: proc "c" (rawptr, cstring, ^i64) -> Result,
    set_float: proc "c" (rawptr, cstring, f64) -> Result,
    get_float: proc "c" (rawptr, cstring, ^f64) -> Result,
    set_string: proc "c" (rawptr, cstring, ^u16) -> Result,
    get_string: proc "c" (rawptr, cstring, ^u16, u32) -> Result,
    set_binary: proc "c" (rawptr, cstring, rawptr, u32) -> Result,
    get_binary: proc "c" (rawptr, cstring, ^rawptr, ^u32) -> Result,
}

IAttributeList :: struct #packed {
    using vtbl: ^IAttributeListVtbl,
}

IAttributeList_iid :: "1e5f0aeb-cc7f-4533-a254-401138ad5ee4"

IStreamAttributesVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_file_name: proc "c" (rawptr, String128) -> Result,
    get_attributes: proc "c" (rawptr) -> ^IAttributeList,
}

IStreamAttributes :: struct #packed {
    using vtbl: ^IStreamAttributesVtbl,
}

IStreamAttributes_iid :: "d6ce2ffc-efaf-4b8c-9e74-f1bb12da44b4"


IRemapParamIDVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_compatible_param_id: proc "c" (rawptr, TUID, u32, ^u32) -> Result,
}

IRemapParamID :: struct #packed {
    using vtbl: ^IRemapParamIDVtbl,
}

IRemapParamID_iid :: "2b88021e-6286-b646-b49d-f76a5663061c"

IComponentHandlerVtbl :: struct #packed {
    using unknown: FUnknownVtbl,

    begin_edit: proc "c" (rawptr, u32) -> Result,
    perform_edit: proc "c" (rawptr, u32, f64) -> Result,
    end_edit: proc "c" (rawptr, u32) -> Result,
    restart_component: proc "c" (rawptr, i32) -> Result,
}

IComponentHandler :: struct #packed {
    using vtbl: ^IComponentHandlerVtbl,
}

IComponentHandler_iid :: "93a0bea3-0bd0-45db-8e89-0b0cc1e46ac6"

IComponentHandler2Vtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_dirty: proc "c" (rawptr, u8) -> Result,
    request_open_editor: proc "c" (rawptr, cstring) -> Result,
    start_group_edit: proc "c" (rawptr) -> Result,
    finish_group_edit: proc "c" (rawptr) -> Result,
}

IComponentHandler2 :: struct #packed {
    using vtbl: ^IComponentHandler2Vtbl,
}

IComponentHandler2_iid :: "f040b4b3-a360-45ec-abcd-c045b4d5a2cc"

IComponentHandlerBusActivationVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    request_bus_activation: proc "c" (rawptr, MediaType, BusDirection, i32, u8) -> Result,
}

IComponentHandlerBusActivation :: struct #packed {
    using vtbl: ^IComponentHandlerBusActivationVtbl,
}

IComponentHandlerBusActivation_iid :: "067d02c1-5b4e-274d-a92d-90fd6eaf7240"

IProgressVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    start: proc "c" (rawptr, ProgressType, ^u16, u64) -> Result,
    update: proc "c" (rawptr, u64, f64) -> Result,
    finish: proc "c" (rawptr, u64) -> Result,
}

IProgress :: struct #packed {
    using vtbl: ^IProgressVtbl,
}

IProgress_iid :: "00c9dc5b-9d90-4254-91a3-88c8b4e91b69"

IEditControllerVtbl :: struct #packed {
    using plugin_base: IPluginBaseVtbl,
    set_component_state: proc "c" (rawptr, ^IBStream) -> Result,
    set_state: proc "c" (rawptr, ^IBStream) -> Result,
    get_state: proc "c" (rawptr, ^IBStream) -> Result,
    get_parameter_count: proc "c" (rawptr) -> i32,
    get_parameter_info: proc "c" (rawptr, i32, ^ParameterInfo) -> Result,
    get_parameter_string_by_value: proc "c" (rawptr, u32, f64, String128) -> Result,
    get_parameter_value_by_string: proc "c" (rawptr, u32, cstring, ^f64) -> Result,
    normalised_param_to_plain: proc "c" (rawptr, u32, f64) -> f64,
    plain_param_to_normalised: proc "c" (rawptr, u32, f64) -> f64,
    get_param_normalised: proc "c" (rawptr, u32) -> f64,
    set_param_normalised: proc "c" (rawptr, u32, f64) -> Result,
    set_component_handler: proc "c" (rawptr, ^IComponentHandler) -> Result,
    create_view: proc "c" (rawptr, cstring) -> ^IPlugView,
}

IEditController :: struct #packed {
    using vtbl: ^IEditControllerVtbl,
}

IEditController_iid :: "dcd7bbe3-7742-448d-a874-aacc979c759e"

IEditController2Vtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    set_knob_mode: proc "c" (rawptr, KnobMode) -> Result,
    open_help: proc "c" (rawptr, u8) -> Result,
    open_about_box: proc "c" (rawptr, u8) -> Result,
}

IEditController2 :: struct #packed {
    using vtbl: ^IEditController2Vtbl,
}

IEditController2_iid :: "7f4efe59-f320-4967-ac27-a3aeafb63038"


IMidiMappingVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_midi_controller_assignment: proc "c" (rawptr, i32, i16, ControllerNumber, ^u32) -> Result,
}

IMidiMapping :: struct #packed {
    using vtbl: ^IMidiMappingVtbl,
}

IMidiMapping_iid :: "df0ff9f7-49b7-4669-b63a-b7327adbf5e5"

IEditControllerHostEditingVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    begin_edit_from_host: proc "c" (rawptr, u32) -> Result,
    end_edit_from_host: proc "c" (rawptr, u32) -> Result,
}

IEditControllerHostEditing :: struct #packed {
    using vtbl: ^IEditControllerHostEditingVtbl
}

IEditControllerHostEditing_iid :: "c1271208-7059-4098-b9dd-34b36bb0195e"

IComponentHandlerSystemTimeVtbl :: struct #packed {
    using unknown: FUnknownVtbl,
    get_system_time: proc "c" (rawptr, ^i64) -> Result,
}

IComponentHandlerSystemTime :: struct #packed {
    using vtbl: ^IComponentHandlerSystemTimeVtbl,
}

IComponentHandlerSystemTime_iid :: "f9e53056-d155-4cd5-b769-5e1b7b0f7745"

IEventListVtbl :: struct #packed {
    using unknown: FUnknownVtbl,

    get_event_count: proc "c" (rawptr) -> i32,
    get_event: proc "c" (rawptr, i32, ^Event) -> Result,
    add_event: proc "c" (rawptr, ^Event) -> Result,
}

IEventList :: struct #packed {
    using vtbl: ^IEventListVtbl,
}

IEventList_iid :: "3a2c4214-3463-49fe-b2c4-f397b9695a44"

IMessageVtbl :: struct #packed {
    using unknown: FUnknownVtbl,

    get_message_id: proc "c" (rawptr) -> cstring,
    set_message_id: proc "c" (rawptr, cstring),
    get_attributes: proc "c" (rawptr) -> ^IAttributeList,
}

IMessage :: struct #packed {
    using vtbl: ^IMessageVtbl,
}

IMessage_iid :: "936f033b-c6c0-47db-bb08-82f813c1e613"

