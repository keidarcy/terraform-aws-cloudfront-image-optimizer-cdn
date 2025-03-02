function handler(event) {
	const request = event.request;
	const originalImagePath = request.uri;
	const normalizedOperations = {};
	const SUPPORTED_FORMATS = ['auto', 'jpeg', 'webp', 'avif', 'png', 'svg', 'gif'];

	if (request.querystring) {
		const operations = Object.keys(request.querystring);
		for (let i = 0; i < operations.length; i++) {
			const operation = operations[i];
			const opValue = request.querystring[operation].value;
			
			switch (operation.toLowerCase()) {
				case 'format': {
					if (opValue && SUPPORTED_FORMATS.includes(opValue.toLowerCase())) {
						let format = opValue.toLowerCase();
						if (format === 'auto') {
							format = 'jpeg';
							if (request.headers.accept) {
								if (request.headers.accept.value.includes('avif')) {
									format = 'avif';
								} else if (request.headers.accept.value.includes('webp')) {
									format = 'webp';
								}
							}
						}
						normalizedOperations.format = format;
					}
					break;
				}
				case 'width': {
					if (opValue) {
						const width = Number.parseInt(opValue, 10);
						if (!Number.isNaN(width) && width > 0) {
							normalizedOperations.width = width.toString();
						}
					}
					break;
				}
				case 'height': {
					if (opValue) {
						const height = Number.parseInt(opValue, 10);
						if (!Number.isNaN(height) && height > 0) {
							normalizedOperations.height = height.toString();
						}
					}
					break;
				}
				case 'quality': {
					if (opValue) {
						const quality = Number.parseInt(opValue, 10);
						if (!Number.isNaN(quality) && quality > 0) {
							normalizedOperations.quality = Math.min(quality, 100).toString();
						}
					}
					break;
				}
				default:
					break;
			}
		}

		if (Object.keys(normalizedOperations).length > 0) {
			const normalizedOperationsArray = [];
			if (normalizedOperations.format) normalizedOperationsArray.push(`format=${normalizedOperations.format}`);
			if (normalizedOperations.quality) normalizedOperationsArray.push(`quality=${normalizedOperations.quality}`);
			if (normalizedOperations.width) normalizedOperationsArray.push(`width=${normalizedOperations.width}`);
			if (normalizedOperations.height) normalizedOperationsArray.push(`height=${normalizedOperations.height}`);
			request.uri = `${originalImagePath}/${normalizedOperationsArray.join(',')}`;
		} else {
			request.uri = `${originalImagePath}/original`;
		}
	} else {
		request.uri = `${originalImagePath}/original`;
	}

	request.querystring = {};
	return request;
}