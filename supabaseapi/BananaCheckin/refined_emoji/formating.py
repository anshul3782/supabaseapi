import os
import re

# Directory containing your JSON files
directory = '.'  # change if needed

for filename in os.listdir(directory):
    if filename.endswith('.json'):
        # Remove leading numbers and hyphen (e.g., "49-" or "49_")
        new_name = re.sub(r'^\d+[-_]*', '', filename)
        new_name = new_name.lower()
        old_path = os.path.join(directory, filename)
        new_path = os.path.join(directory, new_name)
        
        if old_path != new_path:
            os.rename(old_path, new_path)
            print(f'Renamed: {filename} → {new_name}')
