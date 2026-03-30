import SwiftUI

struct DeviceListView: View {
    let hidDeviceManager: HIDDeviceManager

    var body: some View {
        Form {
            Section("Connected Mice") {
                if hidDeviceManager.connectedDevices.isEmpty {
                    Text("No mouse devices detected.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(hidDeviceManager.connectedDevices) { device in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(device.name)
                                    .font(.headline)
                                Text("Vendor: \(device.vendorID) | Product: \(device.productID)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("Slot \(device.slotIndex + 1)")
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(device.isActive ? Color.accentColor : Color.secondary.opacity(0.2))
                                )
                                .foregroundColor(device.isActive ? .white : .primary)

                            if device.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Info") {
                Text("Devices are automatically detected when connected. Each mouse is assigned a cursor slot.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
