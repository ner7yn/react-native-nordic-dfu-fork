import { NativeModules, NativeEventEmitter } from "react-native";
const { RNNordicDfu } = NativeModules;

/**
 * Event emitter for DFU state and progress events
 *
 * @const DFUEmitter
 *
 * @example
 * import { NordicDFU, DFUEmitter } from "react-native-nordic-dfu";
 *
 * DFUEmitter.addlistener("DFUProgress",({percent, currentPart, partsTotal, avgSpeed, speed}) => {
 *   console.log("DFU progress: " + percent +"%");
 * });
 *
 * DFUEmitter.addListener("DFUStateChanged", ({state}) => {
 *   console.log("DFU State:", state);
 * })
 */
const DFUEmitter = new NativeEventEmitter(RNNordicDfu);

export { RNNordicDfu, DFUEmitter };
