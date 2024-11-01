package vst3

import "core:c"

ViewRect :: struct #packed {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
}

NoteExpressionValueDescription :: struct #packed {
    default_value: f64,
    minimum: f64,
    maximum: f64,
    step_count: i32,
}

NoteExpressionValueEvent :: struct #packed {
    type_id: NoteExpressionTypeID,
    note_id: i32,
    value: f64,
}

NoteExpressionTextEvent :: struct #packed {
    type_id: NoteExpressionTypeID,
    note_id: i32,
    text_len: u32,
    text: ^u16,
}

NoteExpressionTypeInfo :: struct #packed {
    type_id: NoteExpressionTypeID,
    title: String128,
    short_title: String128,
    units: String128,
    unit_id: i32,
    value_desc: NoteExpressionValueDescription,
    associated_parameter_id: u32,
    flags: i32,
}

KeyswitchInfo :: struct #packed
{
    type_id: KeyswitchTypeID,
    title: String128,
    short_title: String128,
    keyswitch_min: i32,
    keyswitch_max: i32,
    key_remapped: i32,
    unit_id: i32,
    flags: i32,
}

PhysicalUIMap :: struct #packed {
    physical_ui_type_id: PhysicalUITypeID,
    note_expression_type_id: NoteExpressionTypeID,
};

PhysicalUIMapList :: struct #packed {
    count: u32,
    ui_map: ^PhysicalUIMap,
}

PFactoryInfo :: struct #packed {
    vendor: [64]u8,
    url: [256]u8,
    email: [128]u8,
    flags: i32,
    
}

PClassInfo :: struct #packed {
    cid: TUID,
    cardinality: i32,
    category: [32]u8,
    name: [64]u8,
}

PClassInfo2 :: struct #packed {
    cid: TUID,
    cardinality: i32,
    category: [32]u8,
    name: [64]u8,
    class_flags: u32,
    sub_categories: [128]u8,
    vendor: [64]u8,
    version: [64]u8,
    sdk_version: [64]u8,
}

PClassInfoW :: struct #packed {
    cid: TUID,
    cardinality: i32,
    category: [32]u8,
    name: [64]u16,
    class_flags: u32,
    sub_categories: [128]u8,
    vendor: [64]u16,
    version: [64]u16,
    sdk_version: [64]u16,
}

BusInfo :: struct #packed {
    media_type: MediaType,
    direction: BusDirection,
    channel_count: i32,
    name: String128,
    busType: BusType,
    flags: u32,
};

RoutingInfo :: struct #packed {
    media_type: MediaType,
    bus_index: i32,
    channel: i32,
}

ParameterInfo :: struct #packed {
    id: u32,
    title: String128,
    short_title: String128,
    units: String128,
    step_count: i32,
    default_normalized_value: f64,
    unitId: UnitID,
    flags: i32,
}

FrameRate :: struct #packed {
    framesPerSecond: u32,
    flags: u32,
}

Chord :: struct #packed {
    key_note: u8,
    root_note: u8,
    chord_mask: i16,
}

ProcessContext :: struct #packed {
    state: u32,
    sample_rate: f64,
    project_time_samples: i64,
    system_time: i64,
    continous_time_samples: i64,
    project_time_music: f64,
    bar_position_music: f64,
    cycle_start_music: f64,
    cycle_end_music: f64,
    tempo: f64,
    time_sig_numerator: i32,
    time_sig_denominator: i32, 
    chord: Chord,
    smpte_offset_subframes: i32,
    frame_rate: FrameRate,
    samples_to_next_clock: i32,
}

NoteOnEvent :: struct #packed {
    channel: i16,
    pitch: i16,
    tuning: f32,
    velocity: f32,
    length: i32,
    noteId: i32,
}

NoteOffEvent :: struct #packed {
    channel: i16,
    pitch: i16,
    velocity: f32,
    noteId: i32,
    tuning: f32,
}

DataEvent :: struct #packed {
    size: u32,
    type: u32,
    bytes: ^u8,
}

PolyPressureEvent :: struct #packed {
    channel: i16,
    pitch: i16,
    pressure: f32,
    note_id: i32,
}

ChordEvent :: struct #packed {
    root: i16,
    bassNote: i16,
    mask: i16,
    textLen: u16,
    text: ^u16,
}

ScaleEvent :: struct #packed {
    root: i16,
    mask: i16,
    textLen: u16,
    text: ^u16,
};

LegacyMIDICCOutEvent :: struct #packed {
    controlNumber: u8,
    channel: i8,
    value: i8,
    value2: i8,
}

EventVariant :: struct #raw_union {
    note_on: NoteOnEvent,
    note_off: NoteOffEvent,
    data: DataEvent,
    poly_pressure: PolyPressureEvent,
    note_expression_value: NoteExpressionValueEvent,
    note_expression_text: NoteExpressionTextEvent,
    chord: ChordEvent,
    scale: ScaleEvent,
    midi_cc_out: LegacyMIDICCOutEvent,
}

Event :: struct #packed {
    bus_index: i32,
    sample_offset: i32,
    ppq_position: f64,
    flags: u16,
    type: u16,
    using event: EventVariant,
}

RepresentationInfo :: struct #packed {
    vendor: [64]u8,
    name: [64]u8,
    version: [64]u8,
    host: [64]u8,
}

IContextMenuItem :: struct #packed {
    name: String128,
    tag: i32,
    flags: i32,
}

DataExchangeBlock :: struct #packed {
    data: rawptr,
    size: u32,
    block_id: u32,
}

ProcessSetup :: struct #packed {
    process_mode: i32,
    symbolic_sample_size: i32,
    max_samples_per_block: i32,
    sample_rate: f64,
}

AudioBusBufferVariant :: struct #raw_union {
    buffers_32: ^^f32,
    buffers_64: ^^f64,
}

AudioBusBuffers :: struct #packed {
    num_channels: i32,
    silence_flags: u64,
    using buffers: AudioBusBufferVariant,
};

/*----------------------------------------------------------------------------------------------------------------------
Source: "pluginterfaces/vst/ivstaudioprocessor.h", line 218 */

ProcessData :: struct #packed {
    process_mode: ProcessMode,
    symbolic_sample_size: SymbolicSampleSize,
    num_samples: i32,
    num_inputs: i32,
    num_outputs: i32,
    inputs: ^AudioBusBuffers,
    outputs: ^AudioBusBuffers,
    // struct Steinberg_Vst_IParameterChanges* inputParameterChanges;
    // struct Steinberg_Vst_IParameterChanges* outputParameterChanges;
    input_events: ^IEventList,
    output_events: ^IEventList,
    process_context: ^ProcessContext,
};

UnitInfo :: struct #packed {
    id: UnitID,
    parent_unit_id: UnitID,
    name: String128,
    program_list_id: i32,
}

ProgramListInfo :: struct #packed {
    id: i32,
    name: String128,
    program_count: i32
}

/*----------------------------------------------------------------------------------------------------------------------
----- Interfaces -------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------*/

// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstmessage.h", line 72 */
//
// typedef struct Steinberg_Vst_IConnectionPointVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IConnectionPoint": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* connect) (void* thisInterface, struct Steinberg_Vst_IConnectionPoint* other);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* disconnect) (void* thisInterface, struct Steinberg_Vst_IConnectionPoint* other);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* notify) (void* thisInterface, struct Steinberg_Vst_IMessage* message);
//
// } Steinberg_Vst_IConnectionPointVtbl;
//
// typedef struct Steinberg_Vst_IConnectionPoint
// {
//     struct Steinberg_Vst_IConnectionPointVtbl* lpVtbl;
// } Steinberg_Vst_IConnectionPoint;
//
// static const Steinberg_TUID Steinberg_Vst_IConnectionPoint_iid = SMTG_INLINE_UID (0x70A4156F, 0x6E6E4026, 0x989148BF, 0xAA60D8D1);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstrepresentation.h", line 180 */
//
// typedef struct Steinberg_Vst_IXmlRepresentationControllerVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IXmlRepresentationController": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getXmlRepresentationStream) (void* thisInterface, struct Steinberg_Vst_RepresentationInfo* info, struct Steinberg_IBStream* stream);
//
// } Steinberg_Vst_IXmlRepresentationControllerVtbl;
//
// typedef struct Steinberg_Vst_IXmlRepresentationController
// {
//     struct Steinberg_Vst_IXmlRepresentationControllerVtbl* lpVtbl;
// } Steinberg_Vst_IXmlRepresentationController;
//
// static const Steinberg_TUID Steinberg_Vst_IXmlRepresentationController_iid = SMTG_INLINE_UID (0xA81A0471, 0x48C34DC4, 0xAC30C9E1, 0x3C8393D5);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstcontextmenu.h", line 118 */
//
// typedef struct Steinberg_Vst_IComponentHandler3Vtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IComponentHandler3": */
//     struct Steinberg_Vst_IContextMenu* (SMTG_STDMETHODCALLTYPE* createContextMenu) (void* thisInterface, struct Steinberg_IPlugView* plugView, const Steinberg_Vst_ParamID* paramID);
//
// } Steinberg_Vst_IComponentHandler3Vtbl;
//
// typedef struct Steinberg_Vst_IComponentHandler3
// {
//     struct Steinberg_Vst_IComponentHandler3Vtbl* lpVtbl;
// } Steinberg_Vst_IComponentHandler3;
//
// static const Steinberg_TUID Steinberg_Vst_IComponentHandler3_iid = SMTG_INLINE_UID (0x69F11617, 0xD26B400D, 0xA4B6B964, 0x7B6EBBAB);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstcontextmenu.h", line 146 */
//
// typedef struct Steinberg_Vst_IContextMenuTargetVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IContextMenuTarget": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* executeMenuItem) (void* thisInterface, Steinberg_int32 tag);
//
// } Steinberg_Vst_IContextMenuTargetVtbl;
//
// typedef struct Steinberg_Vst_IContextMenuTarget
// {
//     struct Steinberg_Vst_IContextMenuTargetVtbl* lpVtbl;
// } Steinberg_Vst_IContextMenuTarget;
//
// static const Steinberg_TUID Steinberg_Vst_IContextMenuTarget_iid = SMTG_INLINE_UID (0x3CDF2E75, 0x85D34144, 0xBF86D36B, 0xD7C4894D);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstcontextmenu.h", line 187 */
//
// typedef struct Steinberg_Vst_IContextMenuVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IContextMenu": */
//     Steinberg_int32 (SMTG_STDMETHODCALLTYPE* getItemCount) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getItem) (void* thisInterface, Steinberg_int32 index, Steinberg_Vst_IContextMenu_Item* item, struct Steinberg_Vst_IContextMenuTarget** target);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* addItem) (void* thisInterface, const Steinberg_Vst_IContextMenu_Item* item, struct Steinberg_Vst_IContextMenuTarget* target);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* removeItem) (void* thisInterface, const Steinberg_Vst_IContextMenu_Item* item, struct Steinberg_Vst_IContextMenuTarget* target);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* popup) (void* thisInterface, Steinberg_UCoord x, Steinberg_UCoord y);
//
// } Steinberg_Vst_IContextMenuVtbl;
//
// typedef struct Steinberg_Vst_IContextMenu
// {
//     struct Steinberg_Vst_IContextMenuVtbl* lpVtbl;
// } Steinberg_Vst_IContextMenu;
//
// static const Steinberg_TUID Steinberg_Vst_IContextMenu_iid = SMTG_INLINE_UID (0x2E93C863, 0x0C9C4588, 0x97DBECF5, 0xAD17817D);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstmidilearn.h", line 90 */
//
// typedef struct Steinberg_Vst_IMidiLearnVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IMidiLearn": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* onLiveMIDIControllerInput) (void* thisInterface, Steinberg_int32 busIndex, Steinberg_int16 channel, Steinberg_Vst_CtrlNumber midiCC);
//
// } Steinberg_Vst_IMidiLearnVtbl;
//
// typedef struct Steinberg_Vst_IMidiLearn
// {
//     struct Steinberg_Vst_IMidiLearnVtbl* lpVtbl;
// } Steinberg_Vst_IMidiLearn;
//
// static const Steinberg_TUID Steinberg_Vst_IMidiLearn_iid = SMTG_INLINE_UID (0x6B2449CC, 0x419740B5, 0xAB3C79DA, 0xC5FE5C86);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstchannelcontextinfo.h", line 148 */
//
// typedef struct Steinberg_Vst_ChannelContext_IInfoListenerVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_ChannelContext_IInfoListener": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setChannelContextInfos) (void* thisInterface, struct Steinberg_Vst_IAttributeList* list);
//
// } Steinberg_Vst_ChannelContext_IInfoListenerVtbl;
//
// typedef struct Steinberg_Vst_ChannelContext_IInfoListener
// {
//     struct Steinberg_Vst_ChannelContext_IInfoListenerVtbl* lpVtbl;
// } Steinberg_Vst_ChannelContext_IInfoListener;
//
// static const Steinberg_TUID Steinberg_Vst_ChannelContext_IInfoListener_iid = SMTG_INLINE_UID (0x0F194781, 0x8D984ADA, 0xBBA0C1EF, 0xC011D8D0);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstprefetchablesupport.h", line 79 */
//
// typedef struct Steinberg_Vst_IPrefetchableSupportVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IPrefetchableSupport": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getPrefetchableSupport) (void* thisInterface, Steinberg_Vst_PrefetchableSupport* prefetchable);
//
// } Steinberg_Vst_IPrefetchableSupportVtbl;
//
// typedef struct Steinberg_Vst_IPrefetchableSupport
// {
//     struct Steinberg_Vst_IPrefetchableSupportVtbl* lpVtbl;
// } Steinberg_Vst_IPrefetchableSupport;
//
// static const Steinberg_TUID Steinberg_Vst_IPrefetchableSupport_iid = SMTG_INLINE_UID (0x8AE54FDA, 0xE93046B9, 0xA28555BC, 0xDC98E21E);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstdataexchange.h", line 93 */
//
// typedef struct Steinberg_Vst_IDataExchangeHandlerVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IDataExchangeHandler": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* openQueue) (void* thisInterface, struct Steinberg_Vst_IAudioProcessor* processor, Steinberg_uint32 blockSize, Steinberg_uint32 numBlocks, Steinberg_uint32 alignment, Steinberg_Vst_DataExchangeUserContextID userContextID, Steinberg_Vst_DataExchangeQueueID* outID);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* closeQueue) (void* thisInterface, Steinberg_Vst_DataExchangeQueueID queueID);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* lockBlock) (void* thisInterface, Steinberg_Vst_DataExchangeQueueID queueId, struct Steinberg_Vst_DataExchangeBlock* block);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* freeBlock) (void* thisInterface, Steinberg_Vst_DataExchangeQueueID queueId, Steinberg_Vst_DataExchangeBlockID blockID, Steinberg_TBool sendToController);
//
// } Steinberg_Vst_IDataExchangeHandlerVtbl;
//
// typedef struct Steinberg_Vst_IDataExchangeHandler
// {
//     struct Steinberg_Vst_IDataExchangeHandlerVtbl* lpVtbl;
// } Steinberg_Vst_IDataExchangeHandler;
//
// static const Steinberg_TUID Steinberg_Vst_IDataExchangeHandler_iid = SMTG_INLINE_UID (0x36D551BD, 0x6FF54F08, 0xB48E830D, 0x8BD5A03B);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstdataexchange.h", line 168 */
//
// typedef struct Steinberg_Vst_IDataExchangeReceiverVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IDataExchangeReceiver": */
//     void (SMTG_STDMETHODCALLTYPE* queueOpened) (void* thisInterface, Steinberg_Vst_DataExchangeUserContextID userContextID, Steinberg_uint32 blockSize, Steinberg_TBool* dispatchOnBackgroundThread);
//     void (SMTG_STDMETHODCALLTYPE* queueClosed) (void* thisInterface, Steinberg_Vst_DataExchangeUserContextID userContextID);
//     void (SMTG_STDMETHODCALLTYPE* onDataExchangeBlocksReceived) (void* thisInterface, Steinberg_Vst_DataExchangeUserContextID userContextID, Steinberg_uint32 numBlocks, struct Steinberg_Vst_DataExchangeBlock* blocks, Steinberg_TBool onBackgroundThread);
//
// } Steinberg_Vst_IDataExchangeReceiverVtbl;
//
// typedef struct Steinberg_Vst_IDataExchangeReceiver
// {
//     struct Steinberg_Vst_IDataExchangeReceiverVtbl* lpVtbl;
// } Steinberg_Vst_IDataExchangeReceiver;
//
// static const Steinberg_TUID Steinberg_Vst_IDataExchangeReceiver_iid = SMTG_INLINE_UID (0x45A759DC, 0x84FA4907, 0xABCB6175, 0x2FC786B6);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstautomationstate.h", line 39 */
//
// typedef struct Steinberg_Vst_IAutomationStateVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IAutomationState": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setAutomationState) (void* thisInterface, Steinberg_int32 state);
//
// } Steinberg_Vst_IAutomationStateVtbl;
//
// typedef struct Steinberg_Vst_IAutomationState
// {
//     struct Steinberg_Vst_IAutomationStateVtbl* lpVtbl;
// } Steinberg_Vst_IAutomationState;
//
// static const Steinberg_TUID Steinberg_Vst_IAutomationState_iid = SMTG_INLINE_UID (0xB4E8287F, 0x1BB346AA, 0x83A46667, 0x68937BAB);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstinterappaudio.h", line 38 */
//
// typedef struct Steinberg_Vst_IInterAppAudioHostVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IInterAppAudioHost": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getScreenSize) (void* thisInterface, struct Steinberg_ViewRect* size, float* scale);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* connectedToHost) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* switchToHost) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* sendRemoteControlEvent) (void* thisInterface, Steinberg_uint32 event);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getHostIcon) (void* thisInterface, void** icon);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* scheduleEventFromUI) (void* thisInterface, struct Steinberg_Vst_Event* event);
//     struct Steinberg_Vst_IInterAppAudioPresetManager* (SMTG_STDMETHODCALLTYPE* createPresetManager) (void* thisInterface, const Steinberg_TUID* cid);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* showSettingsView) (void* thisInterface);
//
// } Steinberg_Vst_IInterAppAudioHostVtbl;
//
// typedef struct Steinberg_Vst_IInterAppAudioHost
// {
//     struct Steinberg_Vst_IInterAppAudioHostVtbl* lpVtbl;
// } Steinberg_Vst_IInterAppAudioHost;
//
// static const Steinberg_TUID Steinberg_Vst_IInterAppAudioHost_iid = SMTG_INLINE_UID (0x0CE5743D, 0x68DF415E, 0xAE285BD4, 0xE2CDC8FD);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstinterappaudio.h", line 101 */
//
// typedef struct Steinberg_Vst_IInterAppAudioConnectionNotificationVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IInterAppAudioConnectionNotification": */
//     void (SMTG_STDMETHODCALLTYPE* onInterAppAudioConnectionStateChange) (void* thisInterface, Steinberg_TBool newState);
//
// } Steinberg_Vst_IInterAppAudioConnectionNotificationVtbl;
//
// typedef struct Steinberg_Vst_IInterAppAudioConnectionNotification
// {
//     struct Steinberg_Vst_IInterAppAudioConnectionNotificationVtbl* lpVtbl;
// } Steinberg_Vst_IInterAppAudioConnectionNotification;
//
// static const Steinberg_TUID Steinberg_Vst_IInterAppAudioConnectionNotification_iid = SMTG_INLINE_UID (0x6020C72D, 0x5FC24AA1, 0xB0950DB5, 0xD7D6D5CF);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstinterappaudio.h", line 122 */
//
// typedef struct Steinberg_Vst_IInterAppAudioPresetManagerVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IInterAppAudioPresetManager": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* runLoadPresetBrowser) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* runSavePresetBrowser) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* loadNextPreset) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* loadPreviousPreset) (void* thisInterface);
//
// } Steinberg_Vst_IInterAppAudioPresetManagerVtbl;
//
// typedef struct Steinberg_Vst_IInterAppAudioPresetManager
// {
//     struct Steinberg_Vst_IInterAppAudioPresetManagerVtbl* lpVtbl;
// } Steinberg_Vst_IInterAppAudioPresetManager;
//
// static const Steinberg_TUID Steinberg_Vst_IInterAppAudioPresetManager_iid = SMTG_INLINE_UID (0xADE6FCC4, 0x46C94E1D, 0xB3B49A80, 0xC93FEFDD);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstaudioprocessor.h", line 263 */
//
// typedef struct Steinberg_Vst_IAudioProcessorVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IAudioProcessor": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setBusArrangements) (void* thisInterface, Steinberg_Vst_SpeakerArrangement* inputs, Steinberg_int32 numIns, Steinberg_Vst_SpeakerArrangement* outputs, Steinberg_int32 numOuts);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getBusArrangement) (void* thisInterface, Steinberg_Vst_BusDirection dir, Steinberg_int32 index, Steinberg_Vst_SpeakerArrangement* arr);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* canProcessSampleSize) (void* thisInterface, Steinberg_int32 symbolicSampleSize);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* getLatencySamples) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setupProcessing) (void* thisInterface, struct Steinberg_Vst_ProcessSetup* setup);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setProcessing) (void* thisInterface, Steinberg_TBool state);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* process) (void* thisInterface, struct Steinberg_Vst_ProcessData* data);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* getTailSamples) (void* thisInterface);
//
// } Steinberg_Vst_IAudioProcessorVtbl;
//
// typedef struct Steinberg_Vst_IAudioProcessor
// {
//     struct Steinberg_Vst_IAudioProcessorVtbl* lpVtbl;
// } Steinberg_Vst_IAudioProcessor;
//
// static const Steinberg_TUID Steinberg_Vst_IAudioProcessor_iid = SMTG_INLINE_UID (0x42043F99, 0xB7DA453C, 0xA569E79D, 0x9AAEC33D);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstaudioprocessor.h", line 371 */
//
// typedef struct Steinberg_Vst_IAudioPresentationLatencyVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IAudioPresentationLatency": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setAudioPresentationLatencySamples) (void* thisInterface, Steinberg_Vst_BusDirection dir, Steinberg_int32 busIndex, Steinberg_uint32 latencyInSamples);
//
// } Steinberg_Vst_IAudioPresentationLatencyVtbl;
//
// typedef struct Steinberg_Vst_IAudioPresentationLatency
// {
//     struct Steinberg_Vst_IAudioPresentationLatencyVtbl* lpVtbl;
// } Steinberg_Vst_IAudioPresentationLatency;
//
// static const Steinberg_TUID Steinberg_Vst_IAudioPresentationLatency_iid = SMTG_INLINE_UID (0x309ECE78, 0xEB7D4fae, 0x8B2225D9, 0x09FD08B6);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstaudioprocessor.h", line 404 */
//
// typedef struct Steinberg_Vst_IProcessContextRequirementsVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IProcessContextRequirements": */
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* getProcessContextRequirements) (void* thisInterface);
//
// } Steinberg_Vst_IProcessContextRequirementsVtbl;
//
// typedef struct Steinberg_Vst_IProcessContextRequirements
// {
//     struct Steinberg_Vst_IProcessContextRequirementsVtbl* lpVtbl;
// } Steinberg_Vst_IProcessContextRequirements;
//
// static const Steinberg_TUID Steinberg_Vst_IProcessContextRequirements_iid = SMTG_INLINE_UID (0x2A654303, 0xEF764E3D, 0x95B5FE83, 0x730EF6D0);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivsthostapplication.h", line 35 */
//
// typedef struct Steinberg_Vst_IHostApplicationVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IHostApplication": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getName) (void* thisInterface, Steinberg_Vst_String128 name);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* createInstance) (void* thisInterface, Steinberg_TUID cid, Steinberg_TUID iid, void** obj);
//
// } Steinberg_Vst_IHostApplicationVtbl;
//
// typedef struct Steinberg_Vst_IHostApplication
// {
//     struct Steinberg_Vst_IHostApplicationVtbl* lpVtbl;
// } Steinberg_Vst_IHostApplication;
//
// static const Steinberg_TUID Steinberg_Vst_IHostApplication_iid = SMTG_INLINE_UID (0x58E595CC, 0xDB2D4969, 0x8B6AAF8C, 0x36A664E5);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivsthostapplication.h", line 74 */
//
// typedef struct Steinberg_Vst_IVst3ToVst2WrapperVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
// } Steinberg_Vst_IVst3ToVst2WrapperVtbl;
//
// typedef struct Steinberg_Vst_IVst3ToVst2Wrapper
// {
//     struct Steinberg_Vst_IVst3ToVst2WrapperVtbl* lpVtbl;
// } Steinberg_Vst_IVst3ToVst2Wrapper;
//
// static const Steinberg_TUID Steinberg_Vst_IVst3ToVst2Wrapper_iid = SMTG_INLINE_UID (0x29633AEC, 0x1D1C47E2, 0xBB85B97B, 0xD36EAC61);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivsthostapplication.h", line 94 */
//
// typedef struct Steinberg_Vst_IVst3ToAUWrapperVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
// } Steinberg_Vst_IVst3ToAUWrapperVtbl;
//
// typedef struct Steinberg_Vst_IVst3ToAUWrapper
// {
//     struct Steinberg_Vst_IVst3ToAUWrapperVtbl* lpVtbl;
// } Steinberg_Vst_IVst3ToAUWrapper;
//
// static const Steinberg_TUID Steinberg_Vst_IVst3ToAUWrapper_iid = SMTG_INLINE_UID (0xA3B8C6C5, 0xC0954688, 0xB0916F0B, 0xB697AA44);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivsthostapplication.h", line 114 */
//
// typedef struct Steinberg_Vst_IVst3ToAAXWrapperVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
// } Steinberg_Vst_IVst3ToAAXWrapperVtbl;
//
// typedef struct Steinberg_Vst_IVst3ToAAXWrapper
// {
//     struct Steinberg_Vst_IVst3ToAAXWrapperVtbl* lpVtbl;
// } Steinberg_Vst_IVst3ToAAXWrapper;
//
// static const Steinberg_TUID Steinberg_Vst_IVst3ToAAXWrapper_iid = SMTG_INLINE_UID (0x6D319DC6, 0x60C56242, 0xB32C951B, 0x93BEF4C6);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivsthostapplication.h", line 138 */
//
// typedef struct Steinberg_Vst_IVst3WrapperMPESupportVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IVst3WrapperMPESupport": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* enableMPEInputProcessing) (void* thisInterface, Steinberg_TBool state);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setMPEInputDeviceSettings) (void* thisInterface, Steinberg_int32 masterChannel, Steinberg_int32 memberBeginChannel, Steinberg_int32 memberEndChannel);
//
// } Steinberg_Vst_IVst3WrapperMPESupportVtbl;
//
// typedef struct Steinberg_Vst_IVst3WrapperMPESupport
// {
//     struct Steinberg_Vst_IVst3WrapperMPESupportVtbl* lpVtbl;
// } Steinberg_Vst_IVst3WrapperMPESupport;
//
// static const Steinberg_TUID Steinberg_Vst_IVst3WrapperMPESupport_iid = SMTG_INLINE_UID (0x44149067, 0x42CF4BF9, 0x8800B750, 0xF7359FE3);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstplugview.h", line 44 */
//
// typedef struct Steinberg_Vst_IParameterFinderVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IParameterFinder": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* findParameter) (void* thisInterface, Steinberg_int32 xPos, Steinberg_int32 yPos, Steinberg_Vst_ParamID* resultTag);
//
// } Steinberg_Vst_IParameterFinderVtbl;
//
// typedef struct Steinberg_Vst_IParameterFinder
// {
//     struct Steinberg_Vst_IParameterFinderVtbl* lpVtbl;
// } Steinberg_Vst_IParameterFinder;
//
// static const Steinberg_TUID Steinberg_Vst_IParameterFinder_iid = SMTG_INLINE_UID (0x0F618302, 0x215D4587, 0xA512073C, 0x77B9D383);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstunits.h", line 80 */
//
// typedef struct Steinberg_Vst_IUnitHandlerVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IUnitHandler": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* notifyUnitSelection) (void* thisInterface, Steinberg_Vst_UnitID unitId);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* notifyProgramListChange) (void* thisInterface, Steinberg_Vst_ProgramListID listId, Steinberg_int32 programIndex);
//
// } Steinberg_Vst_IUnitHandlerVtbl;
//
// typedef struct Steinberg_Vst_IUnitHandler
// {
//     struct Steinberg_Vst_IUnitHandlerVtbl* lpVtbl;
// } Steinberg_Vst_IUnitHandler;
//
// static const Steinberg_TUID Steinberg_Vst_IUnitHandler_iid = SMTG_INLINE_UID (0x4B5147F8, 0x4654486B, 0x8DAB30BA, 0x163A3C56);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstunits.h", line 115 */
//
// typedef struct Steinberg_Vst_IUnitHandler2Vtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IUnitHandler2": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* notifyUnitByBusChange) (void* thisInterface);
//
// } Steinberg_Vst_IUnitHandler2Vtbl;
//
// typedef struct Steinberg_Vst_IUnitHandler2
// {
//     struct Steinberg_Vst_IUnitHandler2Vtbl* lpVtbl;
// } Steinberg_Vst_IUnitHandler2;
//
// static const Steinberg_TUID Steinberg_Vst_IUnitHandler2_iid = SMTG_INLINE_UID (0xF89F8CDF, 0x699E4BA5, 0x96AAC9A4, 0x81452B01);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstunits.h", line 144 */
//
// typedef struct Steinberg_Vst_IUnitInfoVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IUnitInfo": */
//     Steinberg_int32 (SMTG_STDMETHODCALLTYPE* getUnitCount) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getUnitInfo) (void* thisInterface, Steinberg_int32 unitIndex, struct Steinberg_Vst_UnitInfo* info);
//     Steinberg_int32 (SMTG_STDMETHODCALLTYPE* getProgramListCount) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getProgramListInfo) (void* thisInterface, Steinberg_int32 listIndex, struct Steinberg_Vst_ProgramListInfo* info);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getProgramName) (void* thisInterface, Steinberg_Vst_ProgramListID listId, Steinberg_int32 programIndex, Steinberg_Vst_String128 name);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getProgramInfo) (void* thisInterface, Steinberg_Vst_ProgramListID listId, Steinberg_int32 programIndex, Steinberg_Vst_CString attributeId, Steinberg_Vst_String128 attributeValue);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* hasProgramPitchNames) (void* thisInterface, Steinberg_Vst_ProgramListID listId, Steinberg_int32 programIndex);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getProgramPitchName) (void* thisInterface, Steinberg_Vst_ProgramListID listId, Steinberg_int32 programIndex, Steinberg_int16 midiPitch, Steinberg_Vst_String128 name);
//     Steinberg_Vst_UnitID (SMTG_STDMETHODCALLTYPE* getSelectedUnit) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* selectUnit) (void* thisInterface, Steinberg_Vst_UnitID unitId);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getUnitByBus) (void* thisInterface, Steinberg_Vst_MediaType type, Steinberg_Vst_BusDirection dir, Steinberg_int32 busIndex, Steinberg_int32 channel, Steinberg_Vst_UnitID* unitId);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setUnitProgramData) (void* thisInterface, Steinberg_int32 listOrUnitId, Steinberg_int32 programIndex, struct Steinberg_IBStream* data);
//
// } Steinberg_Vst_IUnitInfoVtbl;
//
// typedef struct Steinberg_Vst_IUnitInfo
// {
//     struct Steinberg_Vst_IUnitInfoVtbl* lpVtbl;
// } Steinberg_Vst_IUnitInfo;
//
// static const Steinberg_TUID Steinberg_Vst_IUnitInfo_iid = SMTG_INLINE_UID (0x3D4BD6B5, 0x913A4FD2, 0xA886E768, 0xA5EB92C1);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstunits.h", line 214 */
//
// typedef struct Steinberg_Vst_IProgramListDataVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IProgramListData": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* programDataSupported) (void* thisInterface, Steinberg_Vst_ProgramListID listId);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getProgramData) (void* thisInterface, Steinberg_Vst_ProgramListID listId, Steinberg_int32 programIndex, struct Steinberg_IBStream* data);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setProgramData) (void* thisInterface, Steinberg_Vst_ProgramListID listId, Steinberg_int32 programIndex, struct Steinberg_IBStream* data);
//
// } Steinberg_Vst_IProgramListDataVtbl;
//
// typedef struct Steinberg_Vst_IProgramListData
// {
//     struct Steinberg_Vst_IProgramListDataVtbl* lpVtbl;
// } Steinberg_Vst_IProgramListData;
//
// static const Steinberg_TUID Steinberg_Vst_IProgramListData_iid = SMTG_INLINE_UID (0x8683B01F, 0x7B354F70, 0xA2651DEC, 0x353AF4FF);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstunits.h", line 246 */
//
// typedef struct Steinberg_Vst_IUnitDataVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IUnitData": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* unitDataSupported) (void* thisInterface, Steinberg_Vst_UnitID unitID);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getUnitData) (void* thisInterface, Steinberg_Vst_UnitID unitId, struct Steinberg_IBStream* data);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* setUnitData) (void* thisInterface, Steinberg_Vst_UnitID unitId, struct Steinberg_IBStream* data);
//
// } Steinberg_Vst_IUnitDataVtbl;
//
// typedef struct Steinberg_Vst_IUnitData
// {
//     struct Steinberg_Vst_IUnitDataVtbl* lpVtbl;
// } Steinberg_Vst_IUnitData;
//
// static const Steinberg_TUID Steinberg_Vst_IUnitData_iid = SMTG_INLINE_UID (0x6C389611, 0xD391455D, 0xB870B833, 0x94A0EFDD);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstpluginterfacesupport.h", line 53 */
//
// typedef struct Steinberg_Vst_IPlugInterfaceSupportVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IPlugInterfaceSupport": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* isPlugInterfaceSupported) (void* thisInterface, const Steinberg_TUID iid);
//
// } Steinberg_Vst_IPlugInterfaceSupportVtbl;
//
// typedef struct Steinberg_Vst_IPlugInterfaceSupport
// {
//     struct Steinberg_Vst_IPlugInterfaceSupportVtbl* lpVtbl;
// } Steinberg_Vst_IPlugInterfaceSupport;
//
// static const Steinberg_TUID Steinberg_Vst_IPlugInterfaceSupport_iid = SMTG_INLINE_UID (0x4FB58B9E, 0x9EAA4E0F, 0xAB361C1C, 0xCCB56FEA);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstparameterfunctionname.h", line 131 */
//
// typedef struct Steinberg_Vst_IParameterFunctionNameVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IParameterFunctionName": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getParameterIDFromFunctionName) (void* thisInterface, Steinberg_Vst_UnitID unitID, Steinberg_FIDString functionName, Steinberg_Vst_ParamID* paramID);
//
// } Steinberg_Vst_IParameterFunctionNameVtbl;
//
// typedef struct Steinberg_Vst_IParameterFunctionName
// {
//     struct Steinberg_Vst_IParameterFunctionNameVtbl* lpVtbl;
// } Steinberg_Vst_IParameterFunctionName;
//
// static const Steinberg_TUID Steinberg_Vst_IParameterFunctionName_iid = SMTG_INLINE_UID (0x6D21E1DC, 0x91199D4B, 0xA2A02FEF, 0x6C1AE55C);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstparameterchanges.h", line 84 */
//
// typedef struct Steinberg_Vst_IParamValueQueueVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IParamValueQueue": */
//     Steinberg_Vst_ParamID (SMTG_STDMETHODCALLTYPE* getParameterId) (void* thisInterface);
//     Steinberg_int32 (SMTG_STDMETHODCALLTYPE* getPointCount) (void* thisInterface);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* getPoint) (void* thisInterface, Steinberg_int32 index, Steinberg_int32* sampleOffset, Steinberg_Vst_ParamValue* value);
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* addPoint) (void* thisInterface, Steinberg_int32 sampleOffset, Steinberg_Vst_ParamValue value, Steinberg_int32* index);
//
// } Steinberg_Vst_IParamValueQueueVtbl;
//
// typedef struct Steinberg_Vst_IParamValueQueue
// {
//     struct Steinberg_Vst_IParamValueQueueVtbl* lpVtbl;
// } Steinberg_Vst_IParamValueQueue;
//
// static const Steinberg_TUID Steinberg_Vst_IParamValueQueue_iid = SMTG_INLINE_UID (0x01263A18, 0xED074F6F, 0x98C9D356, 0x4686F9BA);
//
// /*----------------------------------------------------------------------------------------------------------------------
// Source: "pluginterfaces/vst/ivstparameterchanges.h", line 119 */
//
// typedef struct Steinberg_Vst_IParameterChangesVtbl
// {
//     /* methods derived from "Steinberg_FUnknown": */
//     Steinberg_tresult (SMTG_STDMETHODCALLTYPE* queryInterface) (void* thisInterface, const Steinberg_TUID iid, void** obj);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* addRef) (void* thisInterface);
//     Steinberg_uint32 (SMTG_STDMETHODCALLTYPE* release) (void* thisInterface);
//
//     /* methods defined in "Steinberg_Vst_IParameterChanges": */
//     Steinberg_int32 (SMTG_STDMETHODCALLTYPE* getParameterCount) (void* thisInterface);
//     struct Steinberg_Vst_IParamValueQueue* (SMTG_STDMETHODCALLTYPE* getParameterData) (void* thisInterface, Steinberg_int32 index);
//     struct Steinberg_Vst_IParamValueQueue* (SMTG_STDMETHODCALLTYPE* addParameterData) (void* thisInterface, const Steinberg_Vst_ParamID* id, Steinberg_int32* index);
//
// } Steinberg_Vst_IParameterChangesVtbl;
//
// typedef struct Steinberg_Vst_IParameterChanges
// {
//     struct Steinberg_Vst_IParameterChangesVtbl* lpVtbl;
// } Steinberg_Vst_IParameterChanges;
//
// static const Steinberg_TUID Steinberg_Vst_IParameterChanges_iid = SMTG_INLINE_UID (0xA4779663, 0x0BB64A56, 0xB44384A8, 0x466FEB9D);
