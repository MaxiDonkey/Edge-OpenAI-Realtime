unit JSON.PolymorphicMapper;

interface

{$REGION 'Dev note'}

(*
    Processing pipeline:
    ====================

      1) Parse input text into TJSONObject.
      2) Normalize JSON “shape” (via RTTI) to match the expected Delphi type:
         - Object expected but array received → take the first object in the array.
         - Array expected but object received → wrap the object into a 1-element array.
         Recursive descent, respecting [JsonName].
      3) Standard hydration with TJson.JsonToObject<T>.
      4) Reinjection:
         - Root: applies RawMaps (or overload-provided Maps).
         - Children: for each object/array/list property whose element inherits from TRawJsonBase,
           apply its RawMaps and recurse.

      Contract for polymorphic properties:
      - Delphi property of type TJSONValue with a **setter** (ownership).
      - [JSONMarshalled(False)] so REST.Json ignores it.
      - Do not put [JsonName] on these members; the key comes from RawMaps.
      - RawMaps keys are relative to the current object (case-insensitive lookup).

      Interop JSON / attributes:
      - Key resolution honors [JsonName] (both REST.Json.Types and REST.JsonReflect; “Name” or “Value”).
      - Case-insensitive search on JSON pairs.

    Memory management
    =================

      - TJSONValue is not refcounted. Reinjected tokens are cloned (CloneOrNil).
      - Setters must call ReplaceJsonValue to free the old token and take ownership of the new one.

*)

{$ENDREGION}

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  REST.Json, REST.Json.Types, REST.JsonReflect,
  System.Rtti, System.TypInfo, System.Math;

type
  TRawMap = record
    /// <summary>
    /// JSON key (relative to the current object)
    /// </summary>
    JsonKey : string;

    /// <summary>
    /// Delphi property name (TJSONValue) to setter
    /// </summary>
    PropName : string;
    class function Create(const AJsonKey, APropName: string): TRawMap; static; inline;
  end;

  TRawJsonBase = class;
  TRawJsonBaseClass = class of TRawJsonBase;

  TRawJsonBase = class
  protected
    /// <summary>
    /// To be overridden in every class that has polymorphic fields
    /// </summary>
    class function RawMaps: TArray<TRawMap>; virtual;

    procedure ReplaceJsonValue(var Target: TJSONValue; const NewValue: TJSONValue);

    {--- Utils JSON / RTTI }
    class function CloneOrNil(const Value: TJSONValue): TJSONValue; static; inline;
    class function FindPropCI(const RttiType: TRttiType; const PropName: string): TRttiProperty; static;
    class function GetValueCI(const JObj: TJSONObject; const Key: string): TJSONValue; static;
    class function JsonKeyForProp(const Prop: TRttiProperty): string; static;

    {--- Reinjection }
    class procedure AssignRawPropertiesByMap(Instance: TObject; const Obj: TJSONObject;
      const Maps: array of TRawMap); static;
    class procedure ReinjectSelf(Instance: TObject; const Obj: TJSONObject); static;
    class procedure ReinjectChildren(Instance: TObject; const Obj: TJSONObject); static;

    {--- Readability/Maintainability Helpers }
    class function GetChildJsonForProp(const Obj: TJSONObject; const Prop: TRttiProperty): TJSONValue; static; inline;
    class function IsRawJsonBaseType(const AType: TRttiType): Boolean; static; inline;
    class function EnsureObjectInstanceForProp(const Instance: TObject; const Prop: TRttiProperty;
      const ChildJson: TJSONValue; out ChildObj: TObject): Boolean; static;
    class function GetListRuntimeInfo(const ListObj: TObject; out CountProp: TRttiProperty;
      out ItemsIdx: TRttiIndexedProperty): Boolean; static;

    class procedure Reinject_ObjectProperty(const Instance: TObject; const Obj: TJSONObject;
      const Ctx: TRttiContext; const Prop: TRttiProperty); static;
    class procedure Reinject_DynArrayProperty(const Instance: TObject; const Obj: TJSONObject;
      const Ctx: TRttiContext; const Prop: TRttiProperty); static;
    class procedure Reinject_ObjectListProperty(const Instance: TObject; const Obj: TJSONObject;
      const Ctx: TRttiContext; const Prop: TRttiProperty); static;

    {--- Normalization: make JSON shape match destination RTTI (object <-> array) }
    class procedure NormalizeJsonForType(const Obj: TJSONObject; const DestType: TRttiType); static;
    class function  FindPairCI(const Obj: TJSONObject; const Key: string): TJSONPair; static; inline;
    class function  IsObjectListType(const AType: TRttiType; out ElemType: TRttiType): Boolean; static;
    class function  GetDynArrayElemType(const AType: TRttiType): TRttiType; static; inline;

  public
    class function IsNull(const Value: TJSONValue): Boolean; static; inline;

    {--- Helpers Try* }
    class function TryAsString(const Value: TJSONValue; out Str: string): Boolean; static; inline;
    class function TryAsObject(const Value: TJSONValue; out Obj: TJSONObject): Boolean; static; inline;
    class function TryAsBoolean(const Value: TJSONValue; out Bool: Boolean): Boolean; static; inline;
    class function TryAsDouble(const Value: TJSONValue; out Float: Double): Boolean; static; inline;
    class function TryAsInt64(const Value: TJSONValue; out IntVal: Int64): Boolean; static;
    class function TryAsInteger(const Value: TJSONValue; out IntVal: Integer): Boolean; static;

    {--- FromJson - deserializer }
    class function FromJson<T: class, constructor>(const S: string): T; overload; static;
    class function FromJson<T: class, constructor>(const S: string; const Maps: array of TRawMap): T; overload; static;
  end;

implementation

  {$REGION 'Dev note'}

(* ----------------------------------------------------------------------
                         JSON.PolymorphicMapper
   ----------------------------------------------------------------------

   Overview
   --------
   JSON.PolymorphicMapper provides a thin, focused layer on top of REST.Json
   to safely deserialize polymorphic fields (a.k.a. union types: string | object
   | number | bool | null) while keeping normal auto-mapping for the rest.

   Key idea:
     1) Let REST.Json build the object graph as usual.
     2) Manually reinject selected raw JSON tokens (as TJSONValue) into
        properties you mark as polymorphic.

   This avoids EConversionError and mapping conflicts when a field’s runtime type
   varies across payloads.

   Why this unit
   -------------
   - Reliability: no fragile interceptors/RTTI casts for union-like fields.
   - Control    : per-class declarative mapping (JsonKey -> Delphi property).
   - Safety     : explicit ownership of TJSONValue; tokens are cloned.
   - Interop    : honors [JsonName('...')] when descending into child objects.
   - Ergonomics : TryAs* helpers to read TJSONValue as string/int/double/bool/null
                  without raising exceptions.

   How it works
   ------------
   Public entry points:
     class function FromJson<T: TRawJsonBase, constructor>(const S: string): T;
     class function FromJson<T: TRawJsonBase, constructor>(const S: string;
                      const Maps: array of TRawMap): T;

   Both call TJson.JsonToObject<T>(S) first (standard hydration).

   Reinjection phase (post-hydration, non-intrusive):
     - ReinjectSelf      : applies the class’s RawMaps to its instance.
     - ReinjectChildren  : recurses into nested children and applies their RawMaps.

   Polymorphic fields are TJSONValue properties with a setter and MUST be marked
   [JSONMarshalled(False)] so REST.Json ignores them. Each class owning such fields
   overrides RawMaps to declare JSON key -> Delphi property mapping.

   Architecture / Key Types
   ------------------------
   - TRawJsonBase : base implementing the reinjection pipeline and TryAs* helpers.
                    Override RawMaps where needed.
   - TRawMap      : small record pairing a JSON key with the target Delphi property.

   JSON key resolution & case
   --------------------------
   - When traversing into children, the JSON key for a property is resolved using
     [JsonName('...')] if present (compatible with REST.Json.Types and
     REST.JsonReflect variants), otherwise the Delphi property name.
   - Key lookup is case-insensitive.

   Supported child shapes
   ----------------------
   1) Simple nested object property:
        property A: TA;
      • If JSON contains an object and A is nil, the unit instantiates A (default
        no-arg constructor) before reinjection.

   2) Dynamic arrays of TRawJsonBase:
        property Items: TArray<TChild>;
      • Assumes REST.Json already created the array and elements.
      • Reinjection runs for min(Length(Items), JSON.Count).

   3) TObjectList<TChild> where TChild inherits TRawJsonBase:
        property List: TObjectList<TChild>;
      • If List is nil and JSON provides an array, the unit instantiates the list
        (default Create).
      • Reinjection runs for min(List.Count, JSON.Count) using Items[Index].
      • It does NOT add or allocate missing elements (keeps behavior non-regressive).

   Interacting with REST.Json
   --------------------------
   - Mark polymorphic TJSONValue properties with [JSONMarshalled(False)] so the
     marshaller ignores them. Do NOT put [JsonName] on those members.
   - Continue to use [JsonName('...')] on regular properties; traversal honors it.

   Public API Quick Reference
   --------------------------
   type
     TMy = class(TRawJsonBase)
     private
       [JSONMarshalled(False)] FPoly: TJSONValue;
       procedure SetPoly(const V: TJSONValue);
     protected
       class function RawMaps: TArray<TRawMap>; override;
     public
       property Poly: TJSONValue read FPoly write SetPoly;
     end;

   class function TMy.RawMaps: TArray<TRawMap>;
   begin
     Result := [ TRawMap.Create('poly', 'poly') ];
   end;

   var obj := TRawJsonBase.FromJson<TMy>(JsonText);

      TryAs* helpers
   var s: string; d: Double; l: Int64; i: Integer; b: Boolean;
   if TRawJsonBase.TryAsString (obj.Poly, s) then ...
   if TRawJsonBase.TryAsDouble (obj.Poly, d) then ...
   if TRawJsonBase.TryAsInt64  (obj.Poly, l) then ...
   if TRawJsonBase.TryAsInteger(obj.Poly, i) then ...
   if TRawJsonBase.TryAsBoolean(obj.Poly, b) then ...
   if TRawJsonBase.IsNull      (obj.Poly)    then ...

   Example with nesting
   --------------------
   type
     TA = class(TRawJsonBase)
     private
       [JSONMarshalled(False)] FBriard: TJSONValue;
       procedure SetBriard(const V: TJSONValue);
     protected
       class function RawMaps: TArray<TRawMap>; override;
     public
       property Briard: TJSONValue read FBriard write SetBriard;
     end;

     TTest = class(TRawJsonBase)
     private
       [JSONMarshalled(False)] FTruncation: TJSONValue;
       FCutoff: Integer;
       FA: TA;
       procedure SetTruncation(const V: TJSONValue);
     protected
       class function RawMaps: TArray<TRawMap>; override;
     public
       property Truncation: TJSONValue read FTruncation write SetTruncation;
       property Cutoff: Integer read FCutoff write FCutoff;
       property A: TA read FA write FA;
     end;

   class function TTest.RawMaps: TArray<TRawMap>;
   begin
     Result := [ TRawMap.Create('truncation', 'truncation') ];
   end;

   class function TA.RawMaps: TArray<TRawMap>;
   begin
     Result := [ TRawMap.Create('briard', 'briard') ];
   end;

      JSON: {"truncation":{"reason":"length"},"Cutoff":42,"a":{"briard":"black"}}
      var t := TRawJsonBase.FromJson<TTest>(Json);

   Version & compatibility notes
   -----------------------------
   - Compatible with REST.Json in recent Delphi versions; recognizes [JsonName]
     from both REST.Json.Types and REST.JsonReflect (attribute property Name/Value).
   - Case-insensitive key lookup for robustness across payloads.
   - Thread-safety: methods use local TRttiContext instances (no shared state).

   Performance considerations
   --------------------------
   - Reinjection uses RTTI; overhead is small for typical payloads. Hot paths can
     cache RawMaps or skip reinjection when RawMaps = [].
   - We avoid ToJSON re-serialization: JsonToObject consumes the original string.

   Extending
   ---------
   - To auto-grow TObjectList<T> when JSON has more items than Count, add a growth
     phase that instantiates missing items via the list’s generic argument type
     (RTTI). Intentionally omitted for non-regression.
   - To support dictionaries/maps of TRawJsonBase, iterate JSON pairs and map into
     the target structure after hydration.

   Gotchas
   -------
   - Do NOT add [JsonName] to polymorphic TJSONValue members; keep them
     [JSONMarshalled(False)] and use RawMaps to bind keys.
   - Always implement the TJSONValue setter using ReplaceJsonValue for memory safety.
   - RawMaps keys are relative to the current object (no nested JSON paths).

   Testing tips
   ------------
   - Unit-test:
     • all TryAs* branches (edge values, nulls)
     • key casing variants ('Truncation' vs 'truncation')
     • nested objects, arrays, and TObjectList<T>
     • presence/absence of optional sections (nil vs instantiation)

   *******************************************************************************)

  {$ENDREGION}

{ TRawMap }

class function TRawMap.Create(const AJsonKey, APropName: string): TRawMap;
begin
  Result.JsonKey  := AJsonKey;
  Result.PropName := APropName;
end;

{ TRawJsonBase }

class function TRawJsonBase.RawMaps: TArray<TRawMap>;
begin
  Result := [];
end;

procedure TRawJsonBase.ReplaceJsonValue(var Target: TJSONValue; const NewValue: TJSONValue);
begin
  if Target <> NewValue then
    begin
      Target.Free;
      Target := NewValue;
    end;
end;

class function TRawJsonBase.CloneOrNil(const Value: TJSONValue): TJSONValue;
begin
  if Assigned(Value) then
    Result := Value.Clone as TJSONValue
  else
    Result := nil;
end;

class function TRawJsonBase.FindPropCI(const RttiType: TRttiType;
  const PropName: string): TRttiProperty;
begin
  Result := nil;
  for var item in RttiType.GetProperties do
    if SameText(item.Name, PropName) then
      Exit(item);
end;

class function TRawJsonBase.GetValueCI(const JObj: TJSONObject;
  const Key: string): TJSONValue;
begin
  Result := nil;
  if JObj = nil then
    Exit;

  for var Pair in JObj do
    if SameText(Pair.JsonString.Value, Key) then
      Exit(Pair.JsonValue);
end;

class function TRawJsonBase.JsonKeyForProp(const Prop: TRttiProperty): string;
var
  Attr  : TCustomAttribute;
  PName : TRttiProperty;

  function IsJsonNameAttr(const ClassName: string): Boolean;
  begin
    Result := SameText(ClassName, 'JsonNameAttribute') or
              SameText(ClassName, 'JSONNameAttribute') or
              SameText(ClassName, 'JsonName') or
              SameText(ClassName, 'JSONName');
  end;

begin
  {---- default: Delphi property name }
  Result := Prop.Name;

  var Context := TRttiContext.Create;
  for Attr in Prop.GetAttributes do
  begin
    if IsJsonNameAttr(Attr.ClassName) then
      begin
        var Type_ := Context.GetType(Attr.ClassType);

        {--- Some versions expose "Name", others "Value" }
        PName := Type_.GetProperty('Name');
        if PName = nil then
          PName := Type_.GetProperty('Value');
        if PName <> nil then
          Exit(PName.GetValue(Attr).AsString);
      end;
  end;
end;

class procedure TRawJsonBase.AssignRawPropertiesByMap(Instance: TObject;
  const Obj: TJSONObject;
  const Maps: array of TRawMap);
begin
  if (Instance = nil) or (Obj = nil) then
    Exit;

  var Context := TRttiContext.Create;
  var Type_ := Context.GetType(Instance.ClassType);

  for var item in Maps do
  begin
    var Prop := FindPropCI(Type_, item.PropName);
    var isValidated :=
      (Prop <> nil) and Prop.IsWritable and (Prop.PropertyType is TRttiInstanceType) and
      TRttiInstanceType(Prop.PropertyType).MetaclassType.InheritsFrom(TJSONValue);
    if isValidated then
      begin
        {--- find CI }
        var JsonVal := GetValueCI(Obj, item.JsonKey);

        {--- Go through the setter -> ownership managed by the setter }
        Prop.SetValue(Instance, TValue.From<TJSONValue>(CloneOrNil(JsonVal)));
      end;
  end;
end;

class procedure TRawJsonBase.ReinjectSelf(Instance: TObject; const Obj: TJSONObject);
var
  Typ  : TRttiType;
  Maps : TArray<TRawMap>;
begin
  if (Instance = nil) or (Obj = nil) then
    Exit;

  if not (Instance is TRawJsonBase) then
    Exit;

  Maps := TRawJsonBaseClass(Instance.ClassType).RawMaps;
  if Length(Maps) = 0 then
    Exit;

  var Context := TRttiContext.Create;
  Typ := Context.GetType(Instance.ClassType);

  for var Item in Maps do
  begin
    var Prop := FindPropCI(Typ, Item.PropName);
    var isValidated :=
      (Prop <> nil) and Prop.IsWritable and (Prop.PropertyType is TRttiInstanceType) and
      TRttiInstanceType(Prop.PropertyType).MetaclassType.InheritsFrom(TJSONValue);
    if isValidated then
      begin
        var JsonVal := GetValueCI(Obj, Item.JsonKey);
        Prop.SetValue(Instance, TValue.From<TJSONValue>(CloneOrNil(JsonVal)));
      end;
  end;
end;

class function TRawJsonBase.GetChildJsonForProp(const Obj: TJSONObject;
  const Prop: TRttiProperty): TJSONValue;
begin
  Result := GetValueCI(Obj, JsonKeyForProp(Prop));
end;

class function TRawJsonBase.IsRawJsonBaseType(const AType: TRttiType): Boolean;
begin
  Result := (AType is TRttiInstanceType) and
            TRttiInstanceType(AType).MetaclassType.InheritsFrom(TRawJsonBase);
end;

class function TRawJsonBase.EnsureObjectInstanceForProp(
  const Instance: TObject;
  const Prop: TRttiProperty;
  const ChildJson: TJSONValue;
  out ChildObj: TObject): Boolean;
var
  InstType : TRttiInstanceType;
  Class_   : TClass;
  Ctor     : TRttiMethod;
  Current  : TValue;
begin
  ChildObj := nil;

  {--- Current value }
  Current := Prop.GetValue(Instance);
  if Current.IsObject then
    ChildObj := Current.AsObject;

  {--- Instantiate if needed and if the JSON provides an object }
  if (ChildObj = nil) and (ChildJson is TJSONObject) then
    begin
      InstType := TRttiInstanceType(Prop.PropertyType);
      Class_ := InstType.MetaclassType;

      var Context := TRttiContext.Create;
      var ChildType := Context.GetType(Class_);
      Ctor := ChildType.GetMethod('Create');

      if Assigned(Ctor) and (Length(Ctor.GetParameters) = 0) then
        ChildObj := Ctor.Invoke(Class_, []).AsObject
      else
        ChildObj := Class_.Create;

      Prop.SetValue(Instance, TValue.From<TObject>(ChildObj));
  end;

  Exit(Assigned(ChildObj));
end;

class function TRawJsonBase.GetListRuntimeInfo(const ListObj: TObject;
  out CountProp: TRttiProperty;
  out ItemsIdx: TRttiIndexedProperty): Boolean;
begin
  CountProp := nil;
  ItemsIdx  := nil;
  if ListObj = nil then
    Exit(False);

  var Context := TRttiContext.Create;
  var Type_ := Context.GetType(ListObj.ClassType);

  CountProp := Type_.GetProperty('Count');
  for var IP in Type_.GetIndexedProperties do
    if SameText(IP.Name, 'Items') then
      begin
        ItemsIdx := IP;
        Break;
      end;

  Result := (CountProp <> nil) and (ItemsIdx <> nil);
end;

{--- Case 1: "object" property }
class procedure TRawJsonBase.Reinject_ObjectProperty(const Instance: TObject;
  const Obj: TJSONObject;
  const Ctx: TRttiContext;
  const Prop: TRttiProperty);
var
  ChildObj : TObject;
begin
  var ChildJson := GetChildJsonForProp(Obj, Prop);
  if not (ChildJson is TJSONObject) then
    Exit;

  if EnsureObjectInstanceForProp(Instance, Prop, ChildJson, ChildObj) then
  begin
    if ChildObj is TRawJsonBase then
      begin
        ReinjectSelf(ChildObj, TJSONObject(ChildJson));
        ReinjectChildren(ChildObj, TJSONObject(ChildJson));
      end;
  end;
end;

{--- Case 2: "TArray<TRawJsonBase>" property }
class procedure TRawJsonBase.Reinject_DynArrayProperty(const Instance: TObject;
  const Obj: TJSONObject;
  const Ctx: TRttiContext;
  const Prop: TRttiProperty);
var
  ArrType  : TRttiDynamicArrayType;
  ElemType : TRttiType;
  JsonArr  : TJSONArray;
  ArrVal   : TValue;
begin
  ArrType := TRttiDynamicArrayType(Prop.PropertyType);
  ElemType := ArrType.ElementType;

  if not IsRawJsonBaseType(ElemType) then
    Exit;

  var ChildJson := GetChildJsonForProp(Obj, Prop);
  if not (ChildJson is TJSONArray) then
    Exit;

  JsonArr := TJSONArray(ChildJson);

  ArrVal := Prop.GetValue(Instance);
  if ArrVal.IsEmpty then
    Exit;

  var N := Min(ArrVal.GetArrayLength, JsonArr.Count);
  for var I := 0 to N - 1 do
  begin
    var ElemVal := ArrVal.GetArrayElement(I);
    if ElemVal.IsObject and (JsonArr.Items[I] is TJSONObject) then
      begin
        var ChildObj := ElemVal.AsObject;
        if ChildObj is TRawJsonBase then
          begin
            ReinjectSelf(ChildObj, TJSONObject(JsonArr.Items[I]));
            ReinjectChildren(ChildObj, TJSONObject(JsonArr.Items[I]));
          end;
      end;
  end;
end;

{--- Case 3: property "TObjectList<T : TRawJsonBase>" }
class procedure TRawJsonBase.Reinject_ObjectListProperty(const Instance: TObject;
  const Obj: TJSONObject;
  const Ctx: TRttiContext;
  const Prop: TRttiProperty);
var
  ListObj   : TObject;
  CountProp : TRttiProperty;
  ItemsIdx  : TRttiIndexedProperty;
begin
  {--- Sub-JSON: table }
  var ChildJson := GetChildJsonForProp(Obj, Prop);
  if not (ChildJson is TJSONArray) then
    Exit;

  var JsonArr := TJSONArray(ChildJson);

  {--- Current list }
  var ListVal := Prop.GetValue(Instance);
  if ListVal.IsObject then
    ListObj := ListVal.AsObject
  else
    ListObj := nil;

  {--- Instantiate the list if necessary (Create without param.) }
  if ListObj = nil then
    begin
      with Ctx.GetType(TRttiInstanceType(Prop.PropertyType).MetaclassType) do
        begin
          var Ctor := GetMethod('Create');
          if Assigned(Ctor) and (Length(Ctor.GetParameters) = 0) then
            ListObj := Ctor.Invoke(TRttiInstanceType(Prop.PropertyType).MetaclassType, []).AsObject
          else
            ListObj := TRttiInstanceType(Prop.PropertyType).MetaclassType.Create;
        end;
      Prop.SetValue(Instance, TValue.From<TObject>(ListObj));
    end;

  if not GetListRuntimeInfo(ListObj, CountProp, ItemsIdx) then
    Exit;

  var Count := CountProp.GetValue(ListObj).AsInteger;
  var N := Min(Count, JsonArr.Count);

  for var I := 0 to N - 1 do
    begin
      var ElemVal := ItemsIdx.GetValue(ListObj, [I]);
      if ElemVal.IsObject and (JsonArr.Items[I] is TJSONObject) then
        begin
          var ChildObj := ElemVal.AsObject;
          if ChildObj is TRawJsonBase then
            begin
              ReinjectSelf(ChildObj, TJSONObject(JsonArr.Items[I]));
              ReinjectChildren(ChildObj, TJSONObject(JsonArr.Items[I]));
            end;
        end;
    end;
end;

class procedure TRawJsonBase.ReinjectChildren(Instance: TObject; const Obj: TJSONObject);
begin
  if (Instance = nil) or (Obj = nil) then
    Exit;

  var Context := TRttiContext.Create;
  var Type_ := Context.GetType(Instance.ClassType);

  for var P in Type_.GetProperties do
  begin
    if not P.IsReadable then
      Continue;

    if P.PropertyType is TRttiInstanceType then
      begin
        {--- Simple object }
        Reinject_ObjectProperty(Instance, Obj, Context, P);

        {--- TObjectList<T> }
        Reinject_ObjectListProperty(Instance, Obj, Context, P);
      end
    else
    if P.PropertyType is TRttiDynamicArrayType then
      begin
        {--- TArray<T> }
        Reinject_DynArrayProperty(Instance, Obj, Context, P);
      end;
  end;
end;

class function TRawJsonBase.FindPairCI(const Obj: TJSONObject; const Key: string): TJSONPair;
begin
  Result := nil;
  if Obj = nil then Exit;
  for var Pair in Obj do
    if SameText(Pair.JsonString.Value, Key) then
      Exit(Pair);
end;

class function TRawJsonBase.GetDynArrayElemType(const AType: TRttiType): TRttiType;
begin
  if AType is TRttiDynamicArrayType then
    Result := TRttiDynamicArrayType(AType).ElementType
  else
    Result := nil;
end;

class function TRawJsonBase.IsObjectListType(const AType: TRttiType; out ElemType: TRttiType): Boolean;
var
  T: TRttiType;
begin
  ElemType := nil;
  Result := False;
  if not (AType is TRttiInstanceType) then Exit;

  {--- RTTI heuristic: TObjectList<T> has an indexer Items[Index]: T }
  T := TRttiContext.Create.GetType(TRttiInstanceType(AType).MetaclassType);
  for var IP in T.GetIndexedProperties do
    if SameText(IP.Name, 'Items') then
      begin
        ElemType := IP.PropertyType;
        Exit(True);
      end;
end;

class procedure TRawJsonBase.NormalizeJsonForType(const Obj: TJSONObject; const DestType: TRttiType);

  {--- Cleanly replace the JSON value of a pair }
  procedure ReplaceValue(Pair: TJSONPair; const NewVal: TJSONValue);
  begin
    if Pair = nil then Exit;
    Pair.JsonValue := NewVal;
  end;

  {--- If we expect a TRawJsonBase object but the JSON has an array:
       we replace with the first object found, then we normalize recursively. }
  procedure NormalizeObjectProp(const P: TRttiProperty; const Pair: TJSONPair);
  var
    V: TJSONValue;
  begin
    V := Pair.JsonValue;

    if V is TJSONArray then
      begin
        var JA := TJSONArray(V);
        for var I := 0 to JA.Count - 1 do
          if JA.Items[I] is TJSONObject then
          begin
            {--- Replace the value of the pair with a CLONE of the 1st object }
            ReplaceValue(Pair, JA.Items[I].Clone as TJSONValue);

            {--- Recursively normalize the new object }
            NormalizeJsonForType(TJSONObject(Pair.JsonValue), P.PropertyType);
            Exit;
          end;
        Exit;
      end;

    if V is TJSONObject then
      NormalizeJsonForType(TJSONObject(V), P.PropertyType);
  end;

  {--- If we expect an array (TArray<T> / TObjectList<T>) but the JSON has an object:
       we wrap it in a 1-element array, then normalize each element. }
  procedure NormalizeArrayProp(const ElemType: TRttiType; const Pair: TJSONPair);
  var
    V: TJSONValue;
  begin
    V := Pair.JsonValue;

    if V is TJSONObject then
      begin
        var JA := TJSONArray.Create;
        JA.AddElement(V.Clone as TJSONValue);
        ReplaceValue(Pair, JA);
        {--- Normalize the single element }
        NormalizeJsonForType(TJSONObject(JA.Items[0]), ElemType);
        Exit;
      end;

    if V is TJSONArray then
      begin
        var JA := TJSONArray(V);
        for var I := 0 to JA.Count - 1 do
          if JA.Items[I] is TJSONObject then
            NormalizeJsonForType(TJSONObject(JA.Items[I]), ElemType);
      end;
  end;

var
  P        : TRttiProperty;
  Key      : string;
  Pair     : TJSONPair;
  ElemType : TRttiType;
begin
  if (Obj = nil) or (DestType = nil) then Exit;

  {--- For each property of the destination type, we align the "shape" (object/array) }
  for P in DestType.GetProperties do
    begin
      if not P.IsReadable then
        Continue;

      {--- respect [JsonName] }
      Key := JsonKeyForProp(P);

      {--- Search is case insensitive }
      Pair := FindPairCI(Obj, Key);
      if Pair = nil then
        Continue;

      {--- Object property (class) }
      if P.PropertyType is TRttiInstanceType then
        begin
          {--- Child TRawJsonBase (expected object) }
          if IsRawJsonBaseType(P.PropertyType) then
            begin
              NormalizeObjectProp(P, Pair);
              Continue;
            end;

          {--- TObjectList<T: TRawJsonBase> (expected array) }
          if IsObjectListType(P.PropertyType, ElemType) and IsRawJsonBaseType(ElemType) then
            begin
              NormalizeArrayProp(ElemType, Pair);
              Continue;
            end;

          {--- Otherwise other class: descend if it is a JSON object }
          if Pair.JsonValue is TJSONObject then
            NormalizeJsonForType(TJSONObject(Pair.JsonValue), P.PropertyType);
        end

      {--- Dynamic array property TArray<T : TRawJsonBase> (expected array) }
      else
      if P.PropertyType is TRttiDynamicArrayType then
        begin
          ElemType := GetDynArrayElemType(P.PropertyType);
          if IsRawJsonBaseType(ElemType) then
            NormalizeArrayProp(ElemType, Pair);
        end;
    end;
end;

class function TRawJsonBase.FromJson<T>(const S: string): T;
begin
  var Root := TJSONObject.ParseJSONValue(S);
  if not Assigned(Root) then
    raise EJSONParseException.Create('Invalid JSON');

  try
    if not (Root is TJSONObject) then
      raise EJSONParseException.Create('JSON Root: Expected Object');

    var Obj := TJSONObject(Root);

    {--- Normalize JSON shape against T }
    var Context := TRttiContext.Create;
    var DestType := Context.GetType(TypeInfo(T));
    NormalizeJsonForType(Obj, DestType);

    {--- Standard Hydration (creates the object tree) }
    Result := TJson.JsonToObject<T>(S);

    {--- Root reinjection + recursion }
    ReinjectSelf(Result, Obj);
    ReinjectChildren(Result, Obj);
  finally
    Root.Free;
  end;
end;

class function TRawJsonBase.FromJson<T>(const S: string; const Maps: array of TRawMap): T;
begin
  var Root := TJSONObject.ParseJSONValue(S);
  if not Assigned(Root) then
    raise EJSONParseException.Create('Invalid JSON');

  try
    if not (Root is TJSONObject) then
      raise EJSONParseException.Create('JSON Root: Expected Object');

    var Obj := TJSONObject(Root);

    {--- Normalize JSON shape against T }
    var Context := TRttiContext.Create;
    var DestType := Context.GetType(TypeInfo(T));
    NormalizeJsonForType(Obj, DestType);

    {--- Standard Hydration }
    Result := TJson.JsonToObject<T>(S);

    {--- Root reinjection via provided maps (root-specific aliases) }
    AssignRawPropertiesByMap(Result, Obj, Maps);

    {--- Recursive reinjection for children (they use their own RawMaps) }
    ReinjectChildren(Result, Obj);
  finally
    Root.Free;
  end;
end;

class function TRawJsonBase.TryAsBoolean(const Value: TJSONValue; out Bool: Boolean): Boolean;
begin
  Bool := False;
  Result := Assigned(Value) and ((Value is TJSONTrue) or (Value is TJSONFalse) or (Value is TJSONBool));
  if Result then
    Bool := Value is TJSONTrue;
end;

class function TRawJsonBase.TryAsDouble(const Value: TJSONValue; out Float: Double): Boolean;
begin
  Float := 0.0;
  Result := Assigned(Value) and (Value is TJSONNumber);
  if Result then
    Float := TJSONNumber(Value).AsDouble;
end;

class function TRawJsonBase.TryAsInt64(const Value: TJSONValue; out IntVal: Int64): Boolean;
begin
  IntVal := 0;
  Result := Assigned(Value) and (Value is TJSONNumber);
  if not Result then Exit;

  var NumAsString := TJSONNumber(Value).ToString;
  if not TryStrToInt64(NumAsString, IntVal) then
    begin
      var D := TJSONNumber(Value).AsDouble;
      if SameValue(Frac(D), 0.0, 1E-12) and (D >= Low(Int64)) and (D <= High(Int64)) then
        begin
          IntVal := Trunc(D);
          Result := True;
        end
      else
        Result := False;
    end;
end;

class function TRawJsonBase.TryAsInteger(const Value: TJSONValue; out IntVal: Integer): Boolean;
var
  L: Int64;
begin
  IntVal := 0;
  Result := TryAsInt64(Value, L) and (L >= Low(Integer)) and (L <= High(Integer));
  if Result then
    IntVal := Integer(L);
end;

class function TRawJsonBase.TryAsObject(const Value: TJSONValue; out Obj: TJSONObject): Boolean;
begin
  Obj := nil;
  Result := Assigned(Value) and (Value is TJSONObject);
  if Result then
    Obj := TJSONObject(Value);
end;

class function TRawJsonBase.TryAsString(const Value: TJSONValue; out Str: string): Boolean;
begin
  Str := '';
  Result := Assigned(Value) and (Value is TJSONString);
  if Result then
    Str := TJSONString(Value).Value;
end;

class function TRawJsonBase.IsNull(const Value: TJSONValue): Boolean;
begin
  Result := (Value = nil) or (Value is TJSONNull);
end;

end.

