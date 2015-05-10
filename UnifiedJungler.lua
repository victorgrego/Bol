--Unified Jungler, by ViktorGrego
-- v0.2 Beta
--[[
  Current Supported Junglers:
  -Nunu
  -Warwick
]]
assert(load(Base64Decode("G0x1YVIAAQQEBAgAGZMNChoKAAAAAAAAAAAAARx9AAAABgBAAEFAAAAdQAABBoBAAAfAQAAdgIAADQBBAEsAAgBKAICCSgAAg0oAgINKAACESgCAhEoAAIWNAEMASoCAhUqAw4aLAAAAywAAAAbBQwAdgYAAQQEEAIQBAADDAQAABAIAAAiAxIgIAMWJCIDFiggAxotLAoAIhkJGAMaCRgAGQ0YARsNGAIZDRgDGA0cABkRGAEaERgCGREYAxoRGAAYFRwBGhUYAhoVGAMbFRgAGxkYARgZHAIbGRgDGxkYAZEIACYsCAAjBQgcAAYMHAEHDBwCBAwgAwUMIAAGECABBxAgAgQQJAMFECQABhQkAQcUJAIEFCgDBRQoAAYYKAEHGCgCBBgsApEIACMsCgAMBQwsAQYMLAIHDCwDBAwwAAUQMAEGEDACBhAsA5EKAAwsDAAZBAw0AgUMNAMGDDQABxA0AQQQOAIFEDgDBhA4AAcUOAEEFDwCBRQ8AwYUPAAHGDwAkQwAGCACDmSUDAAAIAAOgJUMAAAgAg6AlgwAACAADoSXDAAAIAIOhJQMBAAgAA6ElQwEACAADoiWDAQAIAIOiCMBRoyXDAQAIAAOkJQMCAAgAg6QlQwIACAADpSWDAgAIAIOlJcMCAAgAA6YlAwMACACDpiVDAwAIAAOnJYMDAAgAA6ElwwMACACDoh8AgABPAAAABAgAAAByZXF1aXJlAAQLAAAATGlua2VkTGlzdAAEAwAAAG9zAAQGAAAAY2xvY2sAAwAAAAAAwFxABAYAAABHcm9tcAAEBQAAAEJsdWUABAQAAABSZWQABAcAAABXb2x2ZXMABAcAAABHb2xlbXMABAYAAABCaXJkcwAEBwAAAERyYWdvbgADAAAAAAAAJEAEBgAAAEJhcm9uAAMAAAAAAMCSQAQFAAAATGlzdAADAAAAAADghUAEDQAAAG5leHRidXlJbmRleAADAAAAAAAA8D8ECAAAAGxhc3RCdXkAAwAAAAAAAAAABAYAAABnb0J1eQABAAQJAAAAYnV5RGVsYXkAAwAAAAAAAFlABAMAAABfUQAEAwAAAF9FAAQDAAAAX1cABAMAAABfUgAEDgAAAFNSVV9CbHVlMS4xLjEABBMAAABTUlVfQmx1ZU1pbmkyMS4xLjMABBIAAABTUlVfQmx1ZU1pbmkxLjEuMgAEDQAAAFNSVV9SZWQ0LjEuMQAEEQAAAFNSVV9SZWRNaW5pNC4xLjMABBEAAABTUlVfUmVkTWluaTQuMS4yAAQOAAAAU1JVX0tydWc1LjEuMgAEEgAAAFNSVV9LcnVnTWluaTUuMS4xAAQQAAAAU1JVX0dyb21wMTMuMS4xAAQSAAAAU1JVX011cmt3b2xmMi4xLjEABBYAAABTUlVfTXVya3dvbGZNaW5pMi4xLjMABBYAAABTUlVfTXVya3dvbGZNaW5pMi4xLjIABBMAAABTUlVfUmF6b3JiZWFrMy4xLjEABBcAAABTUlVfUmF6b3JiZWFrTWluaTMuMS4yAAQXAAAAU1JVX1Jhem9yYmVha01pbmkzLjEuMwAEFwAAAFNSVV9SYXpvcmJlYWtNaW5pMy4xLjQABA4AAABtb25zdGVyQ2FtcF8xAAQOAAAAbW9uc3RlckNhbXBfMgAEDwAAAG1vbnN0ZXJDYW1wXzEzAAQOAAAAbW9uc3RlckNhbXBfMwAEDgAAAG1vbnN0ZXJDYW1wXzQABA4AAABtb25zdGVyQ2FtcF81AAQJAAAAc2hvcExpc3QAAwAAAAAAPJBAAwAAAAAAAq1AAwAAAAAAEJBAAwAAAAAATq1AAwAAAAAAGq1AAwAAAAAASI9AAwAAAAAAWqhAAwAAAAAAmI9AAwAAAAAAjqhAAwAAAAAAlqlAAwAAAAAAiJBAAwAAAAAAIqhABBIAAABnZXRKdW5nbGVNb25zdGVycwAECQAAAGdldENhbXBzAAQHAAAAT25UaWNrAAQJAAAAT25XbmRNc2cABAkAAABkcmF3TWVudQAEBwAAAE9uTG9hZAAEDAAAAGN1cnJlbnRDYW1wAAAECwAAAHNlbGVjdENhbXAABAkAAABnb3RvQ2FtcAAECwAAAGJhdHRsZUNhbXAABBUAAABqdW5nbGVUYXJnZXRTZWxlY3RvcgAEEAAAAG91dFJlc3Bhd25DYW1wcwAEBAAAAGJ1eQAEBwAAAE9uRHJhdwAQAAAACAAAAAwAAAAAAA0gAAAABgBAAB2AgABBQAAAhoBAAIfAQAHBQAAAYUAFgEaBQABMAcECwAEAAl2BgAFYQMECF8ADgIeBwQKbAQAAFwADgIFBAADFAYAA1QGAAwFCAAChgQGAh8LBAsZCggAYwAIFF4AAgIwCQgAAA4ACnUKA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"), nil, "bt", _ENV))()
