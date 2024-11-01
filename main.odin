package main 

import "core:mem"
import "base:runtime"
import "core:os"
import "vst3"
import "base:intrinsics"
import "core:encoding/uuid"
import "core:strings"
import "core:unicode/utf16"

Component :: struct #packed {
    
}

Plugin :: struct #packed {
    component: Component,
}

parse_uuid :: proc (id: string) -> (uuid.Identifier, vst3.Result) {
    factory_id, err :=  uuid.read (id) 
    if err != nil {
        return {}, vst3.Result.False
    }
    return factory_id, nil
}

query_interface :: proc "c" (this: rawptr, id: cstring, obj: ^rawptr) -> vst3.Result {
    context = runtime.default_context()

    factory_id := parse_uuid(vst3.IPluginFactory_iid) or_return
    factory_2_id := parse_uuid(vst3.IPluginFactory2_iid) or_return
    factory_w_id := parse_uuid(vst3.IPluginFactory3_iid) or_return

    id_string := string(id)
    if id_string == string (factory_id[0 : 16])   ||
       id_string == string (factory_2_id[0 : 16]) ||
       id_string == string (factory_w_id[0 : 16]) {
        obj^ = this
        return vst3.Result.True
    }

    return vst3.Result.NoInterface
}

add_ref :: proc "c" (this: rawptr) -> u32 {
    return 0
}

release :: proc "c" (this: rawptr) -> u32 {
    return 0
}

get_factory_info :: proc "c" (this: rawptr, info: ^vst3.PFactoryInfo) ->  vst3.Result {
    copy(info.url[0 : 256], "hello.com")
    copy(info.email[0 : 128], "edgallyot@gmail.com")
    copy(info.vendor[0 : 64], "the bois")
    info.flags = vst3.kDefaultFactoryFlags
    return vst3.Result.Ok
}

count_classes :: proc "c" (this: rawptr) -> i32 {
    return 1
}

get_class_info :: proc "c" (this: rawptr, idx: i32, info: ^vst3.PClassInfo) -> vst3.Result {
    using vst3
    copy_from_string(info.cid[0 : 16], "cool")
    copy_from_string(info.name[0 : 64], "sami")
    copy_from_string(info.category[0 : 32], "Audio Module Class")
    info.cardinality = cast(i32)vst3.Cardinality.ManyInstances
    return vst3.Result.Ok
}

create_instance :: proc "c" (this: rawptr, class_id: cstring, interface_id: cstring, obj: ^rawptr) -> vst3.Result {
    using vst3
    return Result.NotImplemented
}

get_class_info_2 :: proc "c" (this: rawptr, index: i32, info: ^vst3.PClassInfo2) -> vst3.Result {
    copy_from_string(info.cid[0 : 16], "cool")
    info.cardinality = cast(i32)vst3.Cardinality.ManyInstances
    copy_from_string(info.category[0 : 32], "Audio Module Class")
    copy_from_string(info.name[0 : 64], "sami")
    info.class_flags = cast(u32)vst3.ComponentFlags.SimpleModeSupported
    copy_from_string(info.sub_categories[0 : 128], vst3.kInstrument)
    copy_from_string(info.vendor[0 : 64], "Sami")
    copy_from_string(info.version[0 : 64], "0.0.1")
    copy_from_string(info.sdk_version[0 : 64], vst3.SDKVersionString)
    return vst3.Result.Ok
}

get_class_info_unicode :: proc "c" (this: rawptr, index: i32, info: ^vst3.PClassInfoW) -> vst3.Result {
    context = runtime.default_context()
    copy_from_string(info.cid[0 : 16], "cool")
    info.cardinality = cast(i32)vst3.Cardinality.ManyInstances
    copy_from_string(info.category[0 : 32], "Audio Module Class")
    utf16.encode_string(info.name[0 : 64], "sami")
    info.class_flags = cast(u32)vst3.ComponentFlags.SimpleModeSupported
    copy_from_string(info.sub_categories[0 : 128], vst3.kInstrument)
    utf16.encode_string(info.vendor[0 : 64], "Sami")
    utf16.encode_string(info.version[0 : 64], "0.0.1")
    utf16.encode_string(info.sdk_version[0 : 64], vst3.SDKVersionString)
    return vst3.Result.Ok
}

set_host_context :: proc "c" (this: rawptr, ctx: ^vst3.FUnknown) -> vst3.Result {
    return vst3.Result.Ok
}

Factory :: struct #packed {
    iface: vst3.IPluginFactory3,
    vtbl: vst3.IPluginFactory3Vtbl,
    ref_count : u32,
}

@thread_local x: ^Factory

@export GetPluginFactory :: proc "c" () -> [^]Factory {
    context = runtime.default_context()
    x = new(Factory)
    x.vtbl.query_interface = query_interface
    x.vtbl.add_ref = add_ref 
    x.vtbl.release = release 
    x.vtbl.get_factory_info = get_factory_info 
    x.vtbl.count_classes = count_classes
    x.vtbl.get_class_info = get_class_info 
    x.vtbl.create_instance = create_instance 
    x.vtbl.get_class_info_2 = get_class_info_2 
    x.vtbl.get_class_info_unicode = get_class_info_unicode
    x.vtbl.set_host_context = set_host_context
    x.iface.vtbl = &x.vtbl
    
    return x
}
