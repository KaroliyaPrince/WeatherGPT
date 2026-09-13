const fs = require('fs');
const path = require('path');

function walk(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    if (fs.statSync(dirPath).isDirectory()) {
      walk(dirPath, callback);
    } else {
      callback(dirPath);
    }
  });
}

const hexBgRegex = /bg-\[#[0-9a-fA-F]+\](?:\/[0-9]+)?/g;
const twBgRegex = /bg-(slate|gray|zinc|neutral|blue)-[789]00(?:\/[0-9]+)?/g;

walk('src', function(filepath) {
  if (filepath.endsWith('.tsx') || filepath.endsWith('.ts')) {
    let content = fs.readFileSync(filepath, 'utf8');
    let original = content;
    
    // We will do a simple string replace for all className="..." or className={cn("...")} or className={`...`}
    // First, find all occurrences of className
    let classRegex = /className=(?:\{cn\()?(["'`])(.*?)\1/g;
    
    content = content.replace(classRegex, (match, quote, classes) => {
        let hasDarkBg = hexBgRegex.test(classes) || twBgRegex.test(classes);
        if (!hasDarkBg) return match;
        
        let newClasses = classes.replace(hexBgRegex, '').replace(twBgRegex, '');
        
        // Add glass-panel if missing
        if (!newClasses.includes('glass-panel') && !newClasses.includes('glass-pill') && !newClasses.includes('glass-input') && !newClasses.includes('bg-transparent')) {
            // Check if it's an input-like thing (has placeholder or focus)
            if (newClasses.includes('placeholder:') || newClasses.includes('focus:ring')) {
                newClasses = 'glass-input ' + newClasses;
            } else {
                newClasses = 'glass-panel ' + newClasses;
            }
        }
        
        newClasses = newClasses.replace(/\s+/g, ' ').trim();
        return match.replace(classes, newClasses);
    });
    
    if (content !== original) {
      fs.writeFileSync(filepath, content, 'utf8');
      console.log('Updated', filepath);
    }
  }
});
