use ::input as libinput;
use smithay::backend::input;
use smithay::backend::winit::WinitVirtualDevice;
use smithay::output::Output;

use crate::awm::State;
use crate::protocols::virtual_pointer::VirtualPointer;

pub trait AWMInputBackend: input::InputBackend<Device = Self::AWMDevice> {
    type AWMDevice: AWMInputDevice;
}
impl<T: input::InputBackend> AWMInputBackend for T
where
    Self::Device: AWMInputDevice,
{
    type AWMDevice = Self::Device;
}

pub trait AWMInputDevice: input::Device {
    // FIXME: this should maybe be per-event, not per-device,
    // but it's not clear that this matters in practice?
    // it might be more obvious once we implement it for libinput
    fn output(&self, state: &State) -> Option<Output>;
}

impl AWMInputDevice for libinput::Device {
    fn output(&self, _state: &State) -> Option<Output> {
        // FIXME: Allow specifying the output per-device?
        None
    }
}

impl AWMInputDevice for WinitVirtualDevice {
    fn output(&self, _state: &State) -> Option<Output> {
        // FIXME: we should be returning the single output that the winit backend creates,
        // but for now, that will cause issues because the output is normally upside down,
        // so we apply Transform::Flipped180 to it and that would also cause
        // the cursor position to be flipped, which is not what we want.
        //
        // instead, we just return None and rely on the fact that it has only one output.
        // doing so causes the cursor to be placed in *global* output coordinates,
        // which are not flipped, and happen to be what we want.
        None
    }
}

impl AWMInputDevice for VirtualPointer {
    fn output(&self, _: &State) -> Option<Output> {
        self.output().cloned()
    }
}
