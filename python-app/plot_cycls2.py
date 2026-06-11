import matplotlib.pyplot as plt
import math

def Plot(images, labels, title, username, stage, parts):
    max_images_per_plot = 12
    num_images = len(images)
    num_plots = math.ceil(num_images / max_images_per_plot)

    for plot_index in range(num_plots):
        start_index = plot_index * max_images_per_plot
        end_index = min(start_index + max_images_per_plot, num_images)
        current_images = images[start_index:end_index]
        current_labels = labels[start_index:end_index]

        rows = (len(current_images) // 4) + (1 if len(current_images) % 4 != 0 else 0)
        cols = 4 if len(current_images) >= 4 else len(current_images)

        fig, axes = plt.subplots(rows, cols, figsize=(15, 5 * rows))
        axes = axes.flatten() if rows * cols > 1 else [axes]

        for i, ax in enumerate(axes[:len(current_images)]):
            if current_labels[i]=="Semi":
                coloring="green"
            else:
                coloring="red"

            print(f"Label for image {i}: {current_labels[i]}")  # Debugging: Ensure labels are passed correctly
            ax.imshow(current_images[i], cmap='gray')
            ax.set_xlabel(current_labels[i], fontsize=12, color=coloring, labelpad=10)
            ax.xaxis.set_label_position('bottom')
            ax.axis('on')

        for j in range(len(current_images), len(axes)):
            axes[j].axis('off')

        plt.subplots_adjust(hspace=0.5)  # Ensure there's space for the labels
        plt.suptitle(f"Stage {stage}_Part {parts}_Plot {plot_index + 1}", fontsize=16)
        plt.savefig(f"Plots/{username}/{title}_Stage {stage}_Part {parts}_Plot {plot_index + 1}.png")
        #plt.show()  # Display the plot to check directly
        plt.close()

# Example usage
# images = [your_image_array1, your_image_array2, ..., your_image_arrayN]
# labels = ["Label1", "Label2", ..., "LabelN"]
# Plot(images, labels, "Sample Title", "user123", "Stage1", "Parts1")
