
# eBPF-SE & eBPF-Equivalence-Check Documentation
This Fork tries to merge changes from ebpf-equivalence-check([EQC](https://github.com/sebymiano/ebpf-equivalence-check)).
The intent of EQC is to modify SE and to create a tool to compare functionality of any two eBPF-programs utilizing symbolic execution.
EQC made some changes on top of SE so that the trigger of a symbolic path has changed.
In this documentation I will 1) explain basic workflow in the source code about how SE/EQC works and 2) dig into difference between SE and EQC.

## Feature - Maps Emulation
One of the key change in SE in order to track the change to maps during eBPF program runtime is to emulate maps and map of maps.

[bpf_helper_defs.h](https://github.com/SimonMen65/ebpf-se/blob/main/libbpf-stubbed/src/bpf_helper_defs.h) uses two array structure to store data of all maps. The first array stores structures themselves and the second one records type of corresponding map.
```
void *bpf_map_stubs[MAX_BPF_MAPS];
enum MapStubTypes bpf_map_stub_types[MAX_BPF_MAPS]; 
```
There are 3 types of stubbed structure, MapStub, ArrayStub and MapofMapStub which are defined in [bpf_map_helper_defs.h](https://github.com/SimonMen65/ebpf-se/blob/main/libbpf-stubbed/src/bpf_map_helper_defs.h) 


The following 3 lines in [bpf_helper_defs.h](https://github.com/SimonMen65/ebpf-se/blob/main/libbpf-stubbed/src/bpf_helper_defs.h) define initializations of emulation of maps.
```
#define BPF_MAP_INIT(x,y,z,w) bpf_map_init_stub(x,y,z,w)
#define BPF_MAP_OF_MAPS_INIT(x,y,u,z,w,v) bpf_map_of_maps_init_stub(x,y,u,z,w,v)
#define BPF_MAP_RESET(x) bpf_map_reset_stub(x)
```

With the help of these 3 functions, map emulations should be called in each source code of eBPF programs.

## Difference between SE & EQC




### Different Trigger location of Symbolic Execution Path
The first difference is the different location to call `klee_make_symbolic`.

SE call `make_symbolic` in `map_allocate` and `array_reset`, which are initialization of new MapStub structure and cleaning of array structure.

EQC changes this by calling `make_symbolic` in `array_lookup_elem` and `map_lookup_elem`. 

### Different Content between SE & EQC symbolic execution paths
If we take a closer look at `make_symbolic` parameters between SE and EQC we can find difference between them.

```
In SE:
klee_make_symbolic(map->values_present, max_entries*value_size, map->val_type);
In EQC:
klee_make_symbolic(ret_value, map->value_size, ret_value_str);
```
where ret_value is a special string concatenated from several counters and substrings. One example name is `val_4_vip_stats_map`

To a closer look at how ret_value is assembled:
```
array->lookup_num++;
unsigned_to_string(array->lookup_num, lookup_num_str);
```
EQC added a new field `lookup_num` to `ArrayStub` and each time a lookup performed by calling `array_lookup_elem`, `lookup_num` will be incremented.
The `ret_str` then made by concatenating "val", lookup_num, and name of this array.

`MapStub` shares a similar way of creating symbolic execution path.

### Changed Definition of Helper Functions
Another change worth documentating is the changed definition of `map_of_map_allocate`:
```
In SE:
void *map_of_map_allocate(struct bpf_map_def* inner_map, unsigned int id)
In EQC:
void *map_of_map_allocate(char *outer_name, struct bpf_map_def* inner_map, unsigned int id)
```
EQC record also the outer map name.

# Example programs and Workflow (Command Lines)
Currently we have these examples (already working):
* `crab` - load balancer from the [CRAB project](https://github.com/epfl-dcsl/crab).
* `fw` - firewall from the [hXDP project](https://github.com/axbryd/hXDP-Artifacts).
* `katran` - load balancer from Facebook. ([source](https://github.com/facebookincubator/katran)).
* `fluvia` - IPFIX Exporter from the [Fluvia project](https://github.com/nttcom/fluvia/).
* `hercules` - High speed bulk data transfer application from Network Security Group at ETH Zürich. ([source](https://github.com/netsec-ethz/hercules/))
* `dae` - proxy from the [daeuniverse project](https://github.com/daeuniverse/dae).

And looking forward to debug these two:
* `falco` - kernel monitoring agent from the [Falco project](https://github.com/falcosecurity/libs/).
* `rakelimit`
